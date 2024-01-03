#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "BridgePubItem" asset catalog image resource.
static NSString * const ACImageNameBridgePubItem AC_SWIFT_PRIVATE = @"BridgePubItem";

/// The "CreatePubItem" asset catalog image resource.
static NSString * const ACImageNameCreatePubItem AC_SWIFT_PRIVATE = @"CreatePubItem";

/// The "DeletePubItem" asset catalog image resource.
static NSString * const ACImageNameDeletePubItem AC_SWIFT_PRIVATE = @"DeletePubItem";

/// The "KIT Logo" asset catalog image resource.
static NSString * const ACImageNameKITLogo AC_SWIFT_PRIVATE = @"KIT Logo";

/// The "UnbridgePubItem" asset catalog image resource.
static NSString * const ACImageNameUnbridgePubItem AC_SWIFT_PRIVATE = @"UnbridgePubItem";

#undef AC_SWIFT_PRIVATE