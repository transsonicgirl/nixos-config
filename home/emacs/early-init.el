;;; early-init.el --- runs before the GUI frame and package system -*- lexical-binding: t; -*-

;; Packages are installed by Nix (programs.emacs.extraPackages in
;; home/transsonicgirl.nix). package.el still activates them at startup,
;; which only loads their autoloads from the Nix store; nothing is fetched
;; because no package archives are ever refreshed.

;; Fewer GC pauses during startup; init.el restores a sane threshold.
(setq gc-cons-threshold most-positive-fixnum)

;; Strip GUI chrome before the first frame is drawn (no flicker).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq inhibit-startup-screen t)

;; claude-code's autoloads file uses `transient-define-prefix' directly, which
;; errors at package activation unless the macro can load transient on demand.
(autoload 'transient-define-prefix "transient" nil nil 'macro)
