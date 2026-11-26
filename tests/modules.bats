# The module contract: this is what "tests for all modules" means —
# every directory under modules/ is a module with a guarded makefile,
# and every module goal parses with both of its verbs, through the
# goal-driven inclusion the root Makefile performs for real.

load 'test_helper'

mods_list() {
	(cd "$REPO_ROOT/modules" && ls -d */ | tr -d '/')
}

@test "every module has a makefile behind an include guard" {
	broken=0
	while IFS= read -r mod; do
		mk="$REPO_ROOT/modules/$mod/$mod.mk"
		guard="MOD_$(printf '%s\n' "$mod" | tr 'a-z-' 'A-Z_')"
		if [ ! -f "$mk" ] || ! grep -q "ifndef $guard" "$mk"; then
			echo "bad or missing makefile/guard: $mod"
			broken=1
		fi
	done < <(mods_list)
	[ "$broken" -eq 0 ]
}

@test "every module goal parses" {
	run make -C "$REPO_ROOT" -n $(mods_list)
	[ "$status" -eq 0 ]
}

@test "every module carries a working -update verb" {
	updates=$(for m in $(mods_list); do printf '%s-update ' "$m"; done)
	run make -C "$REPO_ROOT" -n $updates
	[ "$status" -eq 0 ]
}

@test "every module carries a working -uninstall verb" {
	uninstalls=$(for m in $(mods_list); do printf '%s-uninstall ' "$m"; done)
	run make -C "$REPO_ROOT" -n $uninstalls
	[ "$status" -eq 0 ]
}

@test "every profile parses with all of its modules" {
	run make -C "$REPO_ROOT" -n base desktop phone pubnix docker-base
	[ "$status" -eq 0 ]
}

@test "on-demand emulator modules stay out of every profile" {
	for profile_mk in desktop phone pubnix docker-base; do
		if grep -qE 'pcsx2|ppsspp|azahar' "$REPO_ROOT/modules/$profile_mk/$profile_mk.mk"; then
			echo "an emulator leaked into profile: $profile_mk"
			return 1
		fi
	done
}

@test "the desktop profile carries the input-method module" {
	grep -q 'fcitx' "$REPO_ROOT/modules/desktop/desktop.mk"
}

@test "the README's DESKTOP_MODULES example tracks desktop.mk" {
	mk_list=$(sed -n 's/^DESKTOP_MODULES := //p' "$REPO_ROOT/modules/desktop/desktop.mk")
	readme_list=$(sed -n 's/^DESKTOP_MODULES := //p' "$REPO_ROOT/README.org")
	[ -n "$mk_list" ]
	[ "$mk_list" = "$readme_list" ]
}

@test "the dev module guarantees the test toolchain it declares" {
	grep -q 'bats' "$REPO_ROOT/modules/dev/dev.mk"
	grep -q 'shellcheck' "$REPO_ROOT/modules/dev/dev.mk"
	grep -q 'shfmt' "$REPO_ROOT/modules/dev/dev.mk"
}
