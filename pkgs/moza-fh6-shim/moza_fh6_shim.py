#!/usr/bin/env python3
"""Present the MOZA R5 to Forza Horizon 6 as a wheel it will accept.

Forza appears to take input only from wheels it has a database entry for: the
bare R5 and a shim carrying a synthetic product id are both labelled "unknown
device" and driven with a centring spring while contributing no input at all,
whereas a Logitech G29 works on this machine. So by default this mirrors the
wheel onto a uinput device wearing the G29's identity (046d:c24f) and axis
layout, established from the kernel driver rather than guessed: hid-lg.c:51-58
names throttle Y and brake Rz, and lg4ff_raw_event's combine_pedals arithmetic
confirms raw byte 6 is the accelerator and byte 7 the brake.

Force feedback is relayed -- the virtual device advertises whatever effect types
the real wheel supports, and uploads, erases and play/stop commands are
forwarded to it. Forza rejects a wheel with no force feedback outright, so this
is required rather than a nicety.

The real wheel is hidden from the game with SDL_JOYSTICK_BLACKLIST_DEVICES (see
moza-fh6-wrap) and grabbed, so only the shim is visible.
"""

import argparse
import ctypes
import errno
import fcntl
import glob
import os
import select
import signal
import struct
import sys

# linux/input-event-codes.h
EV_SYN, EV_KEY, EV_ABS, EV_FF = 0x00, 0x01, 0x03, 0x15
EV_UINPUT = 0x0101
UI_FF_UPLOAD, UI_FF_ERASE = 1, 2
FF_GAIN, FF_AUTOCENTER, FF_MAX = 0x60, 0x61, 0x7f
ABS_X, ABS_Y, ABS_Z = 0x00, 0x01, 0x02
ABS_RX, ABS_RY, ABS_RZ = 0x03, 0x04, 0x05
ABS_THROTTLE, ABS_RUDDER = 0x06, 0x07
ABS_HAT0X, ABS_HAT0Y = 0x10, 0x11
KEY_MAX, ABS_MAX = 0x2ff, 0x3f

# Two identities, selected with --profile.
#
# "g29" impersonates a Logitech G29 (046d:c24f), a wheel Forza Horizon 6 is
# known to accept on this machine. Its four axes are mirrored in the G29's own
# evdev order, established from the kernel driver: hid-lg.c:51-58 names throttle
# Y and brake Rz, and lg4ff_raw_event's combine_pedals maths confirms raw byte 6
# is the accelerator and byte 7 the brake.
#
# "moza" keeps the real wheel's vendor with a synthetic product id and pads to
# eight axes. It gets the axis usages that Wine's own g920_absolute_usages table
# documents as correct, but the game still labels it "unknown device" and takes
# no input from it -- kept only for comparison.
PROFILES = {
    "g29": {
        "vendor": 0x046D,
        "product": 0xC24F,
        "name": "Logitech G29 Driving Force Racing Wheel",
        "axis_map": {
            ABS_X:        ABS_X,   # steering
            ABS_THROTTLE: ABS_Y,   # gas
            ABS_Z:        ABS_Z,   # clutch
            ABS_RZ:       ABS_RZ,  # brake
            ABS_HAT0X:    ABS_HAT0X,
            ABS_HAT0Y:    ABS_HAT0Y,
        },
        "fillers": (),
        # A real G29 reports its pedals inverted -- 0xFF is released, which is
        # why lg4ff's combine_pedals computes (0xFF + throttle - brake) >> 1
        # around a 0x7F neutral. The MOZA rests at minimum instead, so with the
        # game reading us as a G29 every pedal comes out backwards unless we
        # mirror it. Steering is not inverted.
        "invert": (ABS_Y, ABS_Z, ABS_RZ),
    },
    "moza": {
        "vendor": None,            # inherit from the real wheel
        "product": 0x1004,
        "name": None,              # inherit from the real wheel
        "axis_map": {
            ABS_X:        ABS_X,   # steering -> SDL idx 0 -> HID X
            ABS_THROTTLE: ABS_Y,   # gas      -> SDL idx 1 -> HID Y
            ABS_RZ:       ABS_Z,   # brake    -> SDL idx 2 -> HID Z
            ABS_Z:        ABS_RZ,  # clutch   -> SDL idx 5 -> HID Rz
            ABS_HAT0X:    ABS_HAT0X,
            ABS_HAT0Y:    ABS_HAT0Y,
        },
        # Six axes is not a safe count: bus_sdl.c does
        # `desc.is_gamepad = (axis_count == 6 && button_count >= 14)`, and an
        # is_gamepad device gets an "&XI_" path, which makes
        # windows.gaming.input hand the game a Gamepad instead of a RacingWheel.
        "fillers": (ABS_RX, ABS_RY, ABS_THROTTLE, ABS_RUDDER),
        "invert": (),
    },
}

BY_ID_GLOB = "/dev/input/by-id/usb-Gudsen_MOZA_R5_Base_*-event-joystick"

# The virtual device must be distinguishable from the real one, or there is no
# way to hide the real one from the game: SDL's blacklist hint matches on
# vid/pid, and an identical pair would hide both. Keep the Moza vendor id and
# use a synthetic product id, then force SDL to type it as a wheel with
# SDL_JOYSTICK_WHEEL_DEVICES (see moza-fh6-wrap).

INPUT_EVENT = struct.Struct("llHHi")          # timeval, type, code, value
ABSINFO = struct.Struct("6i")                 # value, min, max, fuzz, flat, resolution
# struct ff_effect is treated as an opaque 48-byte blob; only `id` (s16 at
# offset 2) is ever rewritten, so effect parameters pass through untouched.
FF_EFFECT_SIZE = 48
FF_EFFECT_ID_OFFSET = 2
FF_UPLOAD = struct.Struct(f"Ii{FF_EFFECT_SIZE}s{FF_EFFECT_SIZE}s")  # request_id, retval, effect, old
FF_ERASE = struct.Struct("IiI")               # request_id, retval, effect_id


def _ioc(direction, typ, nr, size):
    return (direction << 30) | (size << 16) | (ord(typ) << 8) | nr


def _ior(typ, nr, size):
    return _ioc(2, typ, nr, size)


def _iow(typ, nr, size):
    return _ioc(1, typ, nr, size)


def _iowr(typ, nr, size):
    return _ioc(3, typ, nr, size)


# NB: UI_SET_*BIT and EVIOCGRAB take their argument by value, not by pointer.
EVIOCGRAB = _iow('E', 0x90, 4)
EVIOCSFF = _iow('E', 0x80, FF_EFFECT_SIZE)
EVIOCRMFF = _iow('E', 0x81, 4)
EVIOCGEFFECTS = _ior('E', 0x84, 4)
UI_SET_FFBIT = _iow('U', 107, 4)
UI_BEGIN_FF_UPLOAD = _iowr('U', 200, FF_UPLOAD.size)
UI_END_FF_UPLOAD = _iow('U', 201, FF_UPLOAD.size)
UI_BEGIN_FF_ERASE = _iowr('U', 202, FF_ERASE.size)
UI_END_FF_ERASE = _iow('U', 203, FF_ERASE.size)
UI_DEV_CREATE = _ioc(0, 'U', 1, 0)
UI_DEV_DESTROY = _ioc(0, 'U', 2, 0)
UI_DEV_SETUP = _iow('U', 3, 92)
UI_ABS_SETUP = _iow('U', 4, 28)
UI_SET_EVBIT = _iow('U', 100, 4)
UI_SET_KEYBIT = _iow('U', 101, 4)
UI_SET_ABSBIT = _iow('U', 103, 4)


def eviocgbit(ev, length):
    return _ior('E', 0x20 + ev, length)


def eviocgabs(axis):
    return _ior('E', 0x40 + axis, ABSINFO.size)


def eviocgid():
    return _ior('E', 0x02, 8)


def eviocgname(length):
    return _ior('E', 0x06, length)


def read_name(fd):
    buf = bytearray(256)
    fcntl.ioctl(fd, eviocgname(len(buf)), buf)
    return buf.split(b"\0", 1)[0].decode(errors="replace")


def find_wheel(explicit=None):
    if explicit:
        return explicit
    matches = sorted(glob.glob(BY_ID_GLOB))
    if not matches:
        sys.exit("no MOZA R5 event device found (is the wheel plugged in?)")
    return matches[0]


def read_bits(fd, ev, maxcode):
    """Return the set of event codes the device supports for `ev`."""
    nbytes = (maxcode + 8) // 8
    buf = bytearray(nbytes)
    try:
        fcntl.ioctl(fd, eviocgbit(ev, nbytes), buf)
    except OSError:
        return set()
    return {c for c in range(maxcode + 1) if buf[c // 8] >> (c % 8) & 1}


def read_absinfo(fd, axis):
    raw = fcntl.ioctl(fd, eviocgabs(axis), bytes(ABSINFO.size))
    return ABSINFO.unpack(raw)


def read_effects_max(fd):
    try:
        return struct.unpack("i", fcntl.ioctl(fd, EVIOCGEFFECTS, bytes(4)))[0]
    except OSError:
        return 0


def create_uinput(src_fd, src_axes, src_keys, src_ff, effects_max, profile):
    """Build the virtual device; returns (fd, name, vendor, invert).

    `invert` maps a destination axis to `lo + hi`, the constant used to mirror
    values for axes whose polarity must be flipped.
    """
    ui = os.open("/dev/uinput", os.O_RDWR | os.O_NONBLOCK)

    events = [EV_KEY, EV_ABS] + ([EV_FF] if src_ff else [])
    for ev in events:
        fcntl.ioctl(ui, UI_SET_EVBIT, ev)
    for code in sorted(src_ff):
        fcntl.ioctl(ui, UI_SET_FFBIT, code)
    for key in sorted(src_keys):
        fcntl.ioctl(ui, UI_SET_KEYBIT, key)

    invert = {}
    for src, dst in sorted(profile["axis_map"].items(), key=lambda kv: kv[1]):
        if src not in src_axes:
            continue
        value, lo, hi, _fuzz, _flat, res = read_absinfo(src_fd, src)
        if dst in profile["invert"]:
            invert[dst] = lo + hi
            value = lo + hi - value
        fcntl.ioctl(ui, UI_SET_ABSBIT, dst)
        # fuzz and flat are forced to 0: the kernel would otherwise derive a
        # deadzone of (hi-lo)>>4 for a joystick collection, ~12% on a 16-bit axis.
        fcntl.ioctl(ui, UI_ABS_SETUP,
                    struct.pack("Hxx6i", dst, value, lo, hi, 0, 0, res))

    for dst in profile["fillers"]:
        fcntl.ioctl(ui, UI_SET_ABSBIT, dst)
        fcntl.ioctl(ui, UI_ABS_SETUP,
                    struct.pack("Hxx6i", dst, -32768, -32768, 32767, 0, 0, 0))

    bustype, src_vendor, _src_product, version = struct.unpack(
        "4H", fcntl.ioctl(src_fd, eviocgid(), bytes(8)))
    vendor = profile["vendor"] or src_vendor
    name = profile["name"] or read_name(src_fd)
    fcntl.ioctl(ui, UI_DEV_SETUP,
                struct.pack("4H80sI", bustype, vendor, profile["product"], version,
                            name.encode()[:79], effects_max))
    fcntl.ioctl(ui, UI_DEV_CREATE)
    return ui, name, vendor, invert


def handle_uinput(ui, ff):
    """Drain force-feedback requests and commands the game sent to the shim."""
    try:
        data = os.read(ui, INPUT_EVENT.size * 64)
    except OSError as exc:
        if exc.errno not in (errno.EAGAIN, errno.EINTR):
            raise
        return
    for off in range(0, len(data) - INPUT_EVENT.size + 1, INPUT_EVENT.size):
        _sec, _usec, etype, code, value = INPUT_EVENT.unpack_from(data, off)
        if etype == EV_UINPUT:
            if code == UI_FF_UPLOAD:
                ff.upload()
            elif code == UI_FF_ERASE:
                ff.erase()
        elif etype == EV_FF:
            ff.command(code, value)


class ForceFeedback:
    """Relay force feedback from the virtual device to the real wheel.

    Effect ids are allocated independently by uinput and by the real device, so
    a mapping is kept between them. Effect payloads are copied verbatim; only
    the id field is rewritten.
    """

    def __init__(self, ui, src_fd):
        self.ui = ui
        self.src_fd = src_fd
        self.ids = {}          # uinput effect id -> real device effect id

    def upload(self):
        buf = bytearray(fcntl.ioctl(self.ui, UI_BEGIN_FF_UPLOAD,
                                    bytes(FF_UPLOAD.size)))
        request_id, _retval, effect, _old = FF_UPLOAD.unpack(buf)
        ui_id = struct.unpack_from("h", effect, FF_EFFECT_ID_OFFSET)[0]

        payload = bytearray(effect)
        # -1 asks the kernel to allocate; an already-known id means this is an
        # update in place, which must reuse the real device's id.
        struct.pack_into("h", payload, FF_EFFECT_ID_OFFSET,
                         self.ids.get(ui_id, -1))
        try:
            out = bytearray(fcntl.ioctl(self.src_fd, EVIOCSFF, bytes(payload)))
            self.ids[ui_id] = struct.unpack_from("h", out, FF_EFFECT_ID_OFFSET)[0]
            retval = 0
        except OSError as exc:
            retval = -exc.errno
        FF_UPLOAD.pack_into(buf, 0, request_id, retval, effect, _old)
        fcntl.ioctl(self.ui, UI_END_FF_UPLOAD, bytes(buf))

    def erase(self):
        buf = bytearray(fcntl.ioctl(self.ui, UI_BEGIN_FF_ERASE,
                                    bytes(FF_ERASE.size)))
        request_id, _retval, ui_id = FF_ERASE.unpack(buf)
        real_id = self.ids.pop(ui_id, None)
        retval = 0
        if real_id is not None:
            try:
                fcntl.ioctl(self.src_fd, EVIOCRMFF, real_id)
            except OSError as exc:
                retval = -exc.errno
        FF_ERASE.pack_into(buf, 0, request_id, retval, ui_id)
        fcntl.ioctl(self.ui, UI_END_FF_ERASE, bytes(buf))

    def command(self, code, value):
        """Forward a play/stop, gain or autocenter command to the real wheel."""
        if code in (FF_GAIN, FF_AUTOCENTER):
            real_code = code
        else:
            real_code = self.ids.get(code)
            if real_code is None:
                return
        try:
            os.write(self.src_fd, INPUT_EVENT.pack(0, 0, EV_FF, real_code, value))
        except OSError:
            pass


def monitor(src_fd):
    """Print every event the real wheel emits, so unmapped controls can be found."""
    names = {EV_KEY: "EV_KEY", EV_ABS: "EV_ABS"}
    seen = {}
    print("press every control (shifter, paddles, d-pad, buttons); Ctrl-C to stop",
          file=sys.stderr)
    try:
        while True:
            data = os.read(src_fd, INPUT_EVENT.size * 64)
            for off in range(0, len(data) - INPUT_EVENT.size + 1, INPUT_EVENT.size):
                _s, _u, etype, code, value = INPUT_EVENT.unpack_from(data, off)
                if etype not in names:
                    continue
                if etype == EV_ABS and seen.get((etype, code)) == value:
                    continue
                seen[(etype, code)] = value
                print(f"{names[etype]:7} code={code:<5} (0x{code:03x})  value={value}")
    except KeyboardInterrupt:
        codes = sorted({c for (t, c) in seen if t == EV_KEY})
        print(f"\nbuttons seen: {[hex(c) for c in codes]}", file=sys.stderr)
        axes = sorted({c for (t, c) in seen if t == EV_ABS})
        print(f"axes seen:    {[hex(c) for c in axes]}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-d", "--device", help="source event node (default: autodetect)")
    ap.add_argument("-p", "--profile", choices=sorted(PROFILES), default="g29",
                    help="identity to present. \"g29\" impersonates a Logitech "
                         "G29, which Forza Horizon 6 has a database entry for; "
                         "\"moza\" keeps the real vendor with a synthetic "
                         "product id, which the game labels \"unknown device\" "
                         "and takes no input from (default: g29)")
    ap.add_argument("--monitor", action="store_true",
                    help="print raw events from the real wheel and exit; use to "
                         "find which codes the shifter, paddles and d-pad emit")
    ap.add_argument("--no-grab", action="store_true",
                    help="leave the real wheel readable by other processes; by "
                         "default it is grabbed so the game cannot pick it up "
                         "instead of the shim")
    args = ap.parse_args()

    path = find_wheel(args.device)
    src_fd = os.open(path, os.O_RDWR)
    src_axes = read_bits(src_fd, EV_ABS, ABS_MAX)
    src_keys = read_bits(src_fd, EV_KEY, KEY_MAX)
    src_ff = read_bits(src_fd, EV_FF, FF_MAX)
    effects_max = read_effects_max(src_fd)

    if args.monitor:
        monitor(src_fd)
        return

    profile = PROFILES[args.profile]
    missing = [hex(a) for a in profile["axis_map"]
               if a not in src_axes and a < ABS_HAT0X]
    if missing:
        print(f"warning: source lacks expected axes {missing}", file=sys.stderr)

    if not src_ff:
        print("warning: the wheel reports no force feedback; FH6 rejects wheels "
              "without it", file=sys.stderr)
    ui, name, vendor, invert = create_uinput(src_fd, src_axes, src_keys, src_ff,
                                             effects_max, profile)
    if not args.no_grab:
        fcntl.ioctl(src_fd, EVIOCGRAB, 1)

    axes = len([d for d in profile["axis_map"].values() if d < ABS_HAT0X]) \
        + len(profile["fillers"])
    print(f"shimming {path} -> {name} "
          f"[{vendor:04x}:{profile['product']:04x}, profile {args.profile}] "
          f"({len(src_keys)} buttons, {axes} axes, "
          f"{len(src_ff)} ff effect types, {effects_max} slots)",
          file=sys.stderr)

    stop = False

    def handle(_signum, _frame):
        nonlocal stop
        stop = True

    signal.signal(signal.SIGINT, handle)
    signal.signal(signal.SIGTERM, handle)

    ff = ForceFeedback(ui, src_fd) if src_ff else None

    try:
        while not stop:
            try:
                ready, _, _ = select.select([src_fd, ui], [], [], 0.5)
            except InterruptedError:
                continue

            if ui in ready and ff is not None:
                handle_uinput(ui, ff)

            if src_fd not in ready:
                continue
            try:
                data = os.read(src_fd, INPUT_EVENT.size * 64)
            except OSError as exc:
                if exc.errno in (errno.EAGAIN, errno.EINTR):
                    continue
                if exc.errno == errno.ENODEV:
                    print("wheel disconnected", file=sys.stderr)
                    break
                raise

            out = bytearray()
            for off in range(0, len(data) - INPUT_EVENT.size + 1, INPUT_EVENT.size):
                sec, usec, etype, code, value = INPUT_EVENT.unpack_from(data, off)
                if etype == EV_ABS:
                    dst = profile["axis_map"].get(code)
                    if dst is None:
                        continue
                    code = dst
                    if dst in invert:
                        value = invert[dst] - value
                elif etype not in (EV_KEY, EV_SYN):
                    continue
                out += INPUT_EVENT.pack(sec, usec, etype, code, value)
            if out:
                os.write(ui, bytes(out))
    finally:
        try:
            fcntl.ioctl(ui, UI_DEV_DESTROY)
        except OSError:
            pass
        os.close(ui)
        os.close(src_fd)
        print("shim stopped", file=sys.stderr)


if __name__ == "__main__":
    main()
