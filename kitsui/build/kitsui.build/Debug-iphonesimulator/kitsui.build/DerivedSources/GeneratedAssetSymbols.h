#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "AppLogo" asset catalog image resource.
static NSString * const ACImageNameAppLogo AC_SWIFT_PRIVATE = @"AppLogo";

/// The "KITLogoD" asset catalog image resource.
static NSString * const ACImageNameKITLogoD AC_SWIFT_PRIVATE = @"KITLogoD";

#undef AC_SWIFT_PRIVATE