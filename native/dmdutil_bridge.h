#pragma once

#include <stdint.h>

#ifdef _MSC_VER
#define VPINDMD_BRIDGE_API __declspec(dllexport)
#else
#define VPINDMD_BRIDGE_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct vpindmd_dmdutil_context vpindmd_dmdutil_context;

typedef struct vpindmd_dmdutil_options {
  int enable_zedmd_usb;
  const char* zedmd_device;
  int enable_zedmd_wifi;
  const char* zedmd_wifi_addr;
  int enable_pixelcade;
  const char* pixelcade_device;
  int enable_pin2dmd;
  int zedmd_brightness;
  int verbose;
} vpindmd_dmdutil_options;

typedef struct vpindmd_display_info {
  int has_display;
  int has_hd_display;
  uint16_t width;
  uint16_t height;
} vpindmd_display_info;

VPINDMD_BRIDGE_API vpindmd_dmdutil_context* vpindmd_dmdutil_create(const vpindmd_dmdutil_options* options);
VPINDMD_BRIDGE_API void vpindmd_dmdutil_destroy(vpindmd_dmdutil_context* context);
VPINDMD_BRIDGE_API int vpindmd_dmdutil_get_info(vpindmd_dmdutil_context* context, vpindmd_display_info* info);
VPINDMD_BRIDGE_API int vpindmd_dmdutil_send_rgb24(vpindmd_dmdutil_context* context, const uint8_t* data, uint16_t width,
                                                  uint16_t height, int buffered);
VPINDMD_BRIDGE_API int vpindmd_dmdutil_clear(vpindmd_dmdutil_context* context, uint16_t width, uint16_t height);
VPINDMD_BRIDGE_API const char* vpindmd_dmdutil_last_error(vpindmd_dmdutil_context* context);

#ifdef __cplusplus
}
#endif
