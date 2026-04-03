#include "dmdutil_bridge.h"

#include "DMDUtil/Config.h"
#include "DMDUtil/DMD.h"

#include <chrono>
#include <cstdarg>
#include <cstdio>
#include <memory>
#include <new>
#include <string>
#include <thread>

struct vpindmd_dmdutil_context {
  std::unique_ptr<DMDUtil::DMD> dmd;
  std::string last_error;
};

namespace {

template <typename T>
concept HasSetSerumPUPTriggers = requires(T* config, bool value) { config->SetSerumPUPTriggers(value); };

template <typename T>
concept HasSetVniKey = requires(T* config, const char* value) { config->SetVniKey(value); };

template <typename T>
concept HasSetExcludeColorizedFramesForZeDMD =
    requires(T* config, bool value) { config->SetExcludeColorizedFramesForZeDMD(value); };

template <typename T>
concept HasSetExcludeColorizedFramesForRGB24DMD =
    requires(T* config, bool value) { config->SetExcludeColorizedFramesForRGB24DMD(value); };

template <typename T>
concept HasSetExcludeColorizedFramesForPIN2DMD =
    requires(T* config, bool value) { config->SetExcludeColorizedFramesForPIN2DMD(value); };

template <typename T>
concept HasSetExcludeColorizedFramesForPixelcade =
    requires(T* config, bool value) { config->SetExcludeColorizedFramesForPixelcade(value); };

template <typename T>
concept HasSetDumpZip = requires(T* config, bool value) { config->SetDumpZip(value); };

template <typename T>
concept HasSetPIN2DMD = requires(T* config, bool value) { config->SetPIN2DMD(value); };

void reset_config(DMDUtil::Config* config) {
  config->SetAltColor(false);
  config->SetAltColorPath("");
  config->SetPUPCapture(false);
  if constexpr (HasSetSerumPUPTriggers<DMDUtil::Config>) config->SetSerumPUPTriggers(false);
  if constexpr (HasSetVniKey<DMDUtil::Config>) config->SetVniKey("");
  config->SetPUPVideosPath("");
  config->SetPUPExactColorMatch(false);
  config->SetIgnoreUnknownFramesTimeout(0);
  config->SetMaximumUnknownFramesToSkip(0);
  config->SetShowNotColorizedFrames(false);
  if constexpr (HasSetExcludeColorizedFramesForZeDMD<DMDUtil::Config>)
    config->SetExcludeColorizedFramesForZeDMD(false);
  if constexpr (HasSetExcludeColorizedFramesForRGB24DMD<DMDUtil::Config>)
    config->SetExcludeColorizedFramesForRGB24DMD(false);
  if constexpr (HasSetExcludeColorizedFramesForPIN2DMD<DMDUtil::Config>)
    config->SetExcludeColorizedFramesForPIN2DMD(false);
  if constexpr (HasSetExcludeColorizedFramesForPixelcade<DMDUtil::Config>)
    config->SetExcludeColorizedFramesForPixelcade(false);
  config->SetDumpNotColorizedFrames(false);
  config->SetDumpFrames(false);
  config->SetDumpPath("");
  if constexpr (HasSetDumpZip<DMDUtil::Config>) config->SetDumpZip(false);
  config->SetFilterTransitionalFrames(false);

  config->SetZeDMD(false);
  config->SetZeDMDDevice("");
  config->SetZeDMDDebug(false);
  config->SetZeDMDBrightness(-1);
  config->SetZeDMDWiFiEnabled(false);
  config->SetZeDMDWiFiAddr("");
  config->SetZeDMDSpiEnabled(false);
  config->SetZeDMDSpiSpeed(72000000);
  config->SetZeDMDSpiFramePause(2);
  config->SetZeDMDWidth(128);
  config->SetZeDMDHeight(32);

  config->SetPixelcade(false);
  config->SetPixelcadeDevice("");
  if constexpr (HasSetPIN2DMD<DMDUtil::Config>) config->SetPIN2DMD(false);

  config->SetDMDServer(false);
  config->SetDMDServerAddr("localhost");
  config->SetDMDServerPort(6789);
  config->SetLocalDisplaysActive(true);
  config->SetLogLevel(DMDUtil_LogLevel_INFO);
  config->SetLogCallback(nullptr);
  config->SetPUPTriggerCallback(nullptr, nullptr);
}

void apply_options(DMDUtil::Config* config, const vpindmd_dmdutil_options* options) {
  reset_config(config);
  if (!options) {
    return;
  }

  config->SetZeDMD(options->enable_zedmd_usb != 0);
  config->SetZeDMDDevice(options->zedmd_device ? options->zedmd_device : "");
  config->SetZeDMDWiFiEnabled(options->enable_zedmd_wifi != 0);
  config->SetZeDMDWiFiAddr(options->zedmd_wifi_addr ? options->zedmd_wifi_addr : "");
  config->SetPixelcade(options->enable_pixelcade != 0);
  config->SetPixelcadeDevice(options->pixelcade_device ? options->pixelcade_device : "");
  if constexpr (HasSetPIN2DMD<DMDUtil::Config>) config->SetPIN2DMD(options->enable_pin2dmd != 0);
  config->SetZeDMDBrightness(options->zedmd_brightness);
  config->SetZeDMDDebug(options->verbose != 0);
  config->SetLogLevel(options->verbose ? DMDUtil_LogLevel_DEBUG : DMDUtil_LogLevel_INFO);
}

void DMDUTILCALLBACK bridge_log_callback(DMDUtil_LogLevel, const char* format, va_list args) {
  vfprintf(stderr, format, args);
  fputc('\n', stderr);
}

bool set_error(vpindmd_dmdutil_context* context, const std::string& message) {
  if (context) {
    context->last_error = message;
  }
  return false;
}

}  // namespace

extern "C" {

vpindmd_dmdutil_context* vpindmd_dmdutil_create(const vpindmd_dmdutil_options* options) {
  auto* context = new (std::nothrow) vpindmd_dmdutil_context();
  if (!context) {
    return nullptr;
  }

  try {
    apply_options(DMDUtil::Config::GetInstance(), options);
    if (options && options->verbose) {
      DMDUtil::Config::GetInstance()->SetLogCallback(bridge_log_callback);
    }
    context->dmd = std::make_unique<DMDUtil::DMD>();
    context->dmd->FindDisplays();
    while (DMDUtil::DMD::IsFinding()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    if (!context->dmd->HasDisplay()) {
      set_error(context, "No displays found by libdmdutil");
      return context;
    }
    return context;
  } catch (const std::exception& exc) {
    set_error(context, exc.what());
    return context;
  } catch (...) {
    set_error(context, "Unknown libdmdutil error");
    return context;
  }
}

void vpindmd_dmdutil_destroy(vpindmd_dmdutil_context* context) {
  delete context;
}

int vpindmd_dmdutil_get_info(vpindmd_dmdutil_context* context, vpindmd_display_info* info) {
  if (!context || !info) {
    return 0;
  }
  info->has_display = (context->dmd && context->dmd->HasDisplay()) ? 1 : 0;
  info->has_hd_display = (context->dmd && context->dmd->HasHDDisplay()) ? 1 : 0;
  info->width = info->has_hd_display ? 256 : 128;
  info->height = info->has_hd_display ? 64 : 32;
  return 1;
}

int vpindmd_dmdutil_send_rgb24(vpindmd_dmdutil_context* context, const uint8_t* data, uint16_t width, uint16_t height,
                               int buffered) {
  if (!context || !context->dmd || !data) {
    return 0;
  }
  try {
    context->dmd->UpdateRGB24Data(data, width, height, buffered != 0);
    return 1;
  } catch (const std::exception& exc) {
    return set_error(context, exc.what()) ? 1 : 0;
  } catch (...) {
    return set_error(context, "Unknown libdmdutil send error") ? 1 : 0;
  }
}

int vpindmd_dmdutil_clear(vpindmd_dmdutil_context* context, uint16_t width, uint16_t height) {
  if (!context || !context->dmd) {
    return 0;
  }
  try {
    const size_t size = static_cast<size_t>(width) * static_cast<size_t>(height) * 3U;
    std::string black(size, '\0');
    context->dmd->UpdateRGB24Data(reinterpret_cast<const uint8_t*>(black.data()), width, height, false);
    return 1;
  } catch (const std::exception& exc) {
    return set_error(context, exc.what()) ? 1 : 0;
  } catch (...) {
    return set_error(context, "Unknown libdmdutil clear error") ? 1 : 0;
  }
}

const char* vpindmd_dmdutil_last_error(vpindmd_dmdutil_context* context) {
  if (!context) {
    return "Invalid libdmdutil context";
  }
  return context->last_error.c_str();
}

}  // extern "C"
