TARGET = bato-nix

BUILD_STORE = wsl-proxy-vm
BUILD_OUT_FILE = .last_build.txt

.PHONY: %

qcow: qcow-build qcow-copy

#time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --eval-store auto --store 'ssh-ng://$(BUILD_STORE)' --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
# IMG_PATH=$(shell cat $(BUILD_OUT_FILE) | jq .[].outputs.out -r ); [ ! -z "$$IMG_PATH" ] && time scp $(BUILD_STORE):"$$IMG_PATH/"*.qcow2 ./"$(TARGET).qcow2"
#time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --eval-store auto --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
qcow-build: ensure-target
	time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
qcow-copy: ensure-target
	[ -f "./result/nixos.qcow2" ] && rm -f ./_utm/"$(TARGET).qcow2" && time cp -L "./result/nixos.qcow2" ./_utm/"$(TARGET).qcow2"

################################################################################
# Helpers
################################################################################

ensure-target:
ifndef TARGET
	$(error TARGET is undefined)
endif
