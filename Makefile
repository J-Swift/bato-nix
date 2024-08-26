TARGET = bato-nix
TARGET_IP = 192.168.64.9

BUILD_STORE = wsl-proxy-vm
BUILD_OUT_FILE = .last_build.txt

.PHONY: %

qcow: qcow-build qcow-copy

#time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --eval-store auto --store 'ssh-ng://$(BUILD_STORE)' --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
# IMG_PATH=$(shell cat $(BUILD_OUT_FILE) | jq .[].outputs.out -r ); [ ! -z "$$IMG_PATH" ] && time scp $(BUILD_STORE):"$$IMG_PATH/"*.qcow2 ./"$(TARGET).qcow2"
#time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --eval-store auto --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
#time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow --eval-store auto --store 'ssh-ng://$(BUILD_STORE)' --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"

qcow-build: ensure-target
	time nix build .#nixosConfigurations.$(TARGET).config.formats.qcow-efi --json --print-build-logs --verbose | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
qcow-copy: ensure-target
	[ -f "./result/nixos.qcow2" ] && rm -f ./_utm/"$(TARGET).qcow2" && cp -L "./result/nixos.qcow2" ./_utm/"$(TARGET).qcow2"
	utm-rebuild

deploy: ensure-target
	time nix run .#nixinate.$(TARGET)

deploy-proxy: ensure-target ensure-target-ip
	time nix build .#nixosConfigurations.$(TARGET).config.system.build.toplevel --eval-store auto --store 'ssh-ng://$(BUILD_STORE)' --json -L | tee $(BUILD_OUT_FILE); exit "$${PIPESTATUS[0]}"
	IMG_PATH=$(shell cat $(BUILD_OUT_FILE) | jq .[].outputs.out -r ); [ ! -z "$$IMG_PATH" ] && time nix copy --from 'ssh-ng://$(BUILD_STORE)' --to 'ssh-ng://$(TARGET_IP)' $$IMG_PATH
	$(MAKE) deploy TARGET=$(TARGET)

################################################################################
# Helpers
################################################################################

ensure-target:
ifndef TARGET
	$(error TARGET is undefined)
endif

ensure-target-ip:
ifndef TARGET_IP
	$(error TARGET_IP is undefined)
endif
