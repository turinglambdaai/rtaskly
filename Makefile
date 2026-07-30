# Taskly — Noise build pipeline.
#
# Mirrors the recipe from Noise's Template/Makefile and the
# NoiseBackendExample/Makefile, adapted for a macOS desktop app.
#
# On macOS (unlike iOS) we use the stock `raco` (no pbraco / special PB
# Racket build is needed).
#
# Two artifacts are produced from the Racket sources and bundled into
# the macOS app:
#
#   1. res/core.zo   - the compiled, self-contained Racket module bundle
#                      (runtime + bytecode) that the app embeds.
#   2. Backend.swift - the generated Swift client (serde types + one
#                      method per define-rpc). Checked into the app so
#                      Xcode compiles it with the rest of the sources.
#
# Run `make` whenever you change taskly-core/*.rkt.

ARCH      = $(shell uname -m)
APP_SRC   = Taskly
RKT_SRC   = taskly-core
RKT_FILES = $(shell find $(RKT_SRC) -name '*.rkt')
RKT_MAIN  = $(RKT_SRC)/main.rkt

RESOURCES_PATH = $(APP_SRC)/res
RUNTIME_NAME   = runtime-$(ARCH)
RUNTIME_PATH   = $(RESOURCES_PATH)/$(RUNTIME_NAME)
CORE_ZO        = $(RESOURCES_PATH)/core.zo

.PHONY: all clean install

all: $(CORE_ZO) $(APP_SRC)/Backend.swift

# --- Racket-side dependencies (noise-serde-lib) ------------------------
# Ensures noise-serde-lib is installed so `raco make` / codegen resolve.
install:
	raco pkg install --auto --name taskly-core ./$(RKT_SRC) || true
	raco pkg install --auto ../Noise/Racket/noise-serde-lib ../Noise/Racket/noise-serde-doc || true

# --- 1. compile Racket to bytecode bundle -------------------------------
$(CORE_ZO): $(RKT_FILES)
	mkdir -p $(RESOURCES_PATH)
	rm -fr $(RUNTIME_PATH)
	raco ctool \
		--runtime $(RUNTIME_PATH) \
		--runtime-access $(RUNTIME_NAME) \
		--mods $@ $(RKT_MAIN)

# --- 2. generate the Swift client ---------------------------------------
# Uses `raco noise-serde-codegen` when the command is registered; falls back
# to invoking the codegen submodule directly (needed when noise-serde-lib
# was installed with --no-setup, so the raco command isn't registered).
$(APP_SRC)/Backend.swift: $(RKT_FILES)
	@if raco noise-serde-codegen $(RKT_MAIN) > $@ 2>/dev/null; then \
		echo "[codegen] raco noise-serde-codegen"; \
	else \
		echo "[codegen] fallback: direct submodule"; \
		./bin/codegen $(RKT_MAIN) > $@; \
	fi

clean:
	rm -rf $(RESOURCES_PATH)
