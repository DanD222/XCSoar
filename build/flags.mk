CXX_FEATURES = -std=c++20
CXX_FEATURES += -fno-threadsafe-statics
CXX_FEATURES += -fmerge-all-constants

HOST_CXX_FEATURES := -std=c++17

ifeq ($(CLANG),n)
CXX_FEATURES += -fcoroutines
CXX_FEATURES += -fconserve-space -fno-operator-names
else
CXX_FEATURES += -fcoroutines-ts
# suppress clang 16 warning "the '-fcoroutines-ts' flag is deprecated
# and it will be removed in Clang 17"; TODO: remove -fcoroutines-ts
# eventually
ifneq ($(TARGET_IS_DARWIN),y)
    ifeq ($(shell expr $(shell echo $(CXX_VERSION) | cut -f1 -d.) \>= 14), 1)
        CXX_FEATURES += -Wno-deprecated-experimental-coroutine
    endif
endif
endif

# Need GNU extensions for sources generated by tools/BinToC.pm
C_FEATURES = -std=gnu11

# produce position independent code when compiling the python library
ifeq ($(MAKECMDGOALS),python)
CXX_FEATURES += -fPIC
C_FEATURES += -fPIC
LDFLAGS += -fPIC -shared
endif

ifeq ($(ICF),y)
  LDFLAGS += -Wl,--icf=all

  ifeq ($(CLANG),y)
    USE_LD = lld
  else
    USE_LD = gold
  endif

  # Hide all symbols from static libraries we link with; this has a
  # huge effect on Android where libc++'s symbols are exported by
  # default.
  LDFLAGS += -Wl,--exclude-libs,ALL
endif

ifneq ($(USE_LD),)
LDFLAGS += -fuse-ld=$(USE_LD)
endif

ifneq ($(MAKECMDGOALS),python)
ifeq ($(HAVE_WIN32),n)
CXX_FEATURES += -fvisibility=hidden
C_FEATURES += -fvisibility=hidden
endif
endif

ifeq ($(DEBUG)$(HAVE_WIN32)$(TARGET_IS_DARWIN),nnn)
CXX_FEATURES += -ffunction-sections
C_FEATURES += -ffunction-sections
TARGET_LDFLAGS += -Wl,--gc-sections
endif

ALL_CPPFLAGS = $(TARGET_INCLUDES) $(INCLUDES) $(TARGET_CPPFLAGS) $(CPPFLAGS)
ALL_CXXFLAGS = $(OPTIMIZE) $(TARGET_OPTIMIZE) $(FLAGS_PROFILE) $(SANITIZE_FLAGS) $(CXX_FEATURES) $(TARGET_CXXFLAGS) $(CXX_WARNINGS) $(CXXFLAGS)
ALL_CFLAGS = $(OPTIMIZE) $(TARGET_OPTIMIZE) $(FLAGS_PROFILE) $(SANITIZE_FLAGS) $(C_FEATURES) $(C_WARNINGS) $(CFLAGS)

ALL_LDFLAGS = $(OPTIMIZE_LDFLAGS)
ifeq ($(LTO),y)
  # Pass warning flags to the linker when using LTO optimizations. LTO means that second stage compilation happens here,
  # and compiler warnings can occur here too.
  ALL_LDFLAGS += $(CXX_WARNINGS)
endif
ALL_LDFLAGS += $(TARGET_LDFLAGS) $(FLAGS_PROFILE) $(SANITIZE_FLAGS) $(LDFLAGS)

ALL_LDLIBS = $(TARGET_LDLIBS) $(COVERAGE_LDLIBS) $(LDLIBS) $(EXTRA_LDLIBS)
