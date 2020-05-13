args @ { fetchurl, ... }:
rec {
  baseName = ''lack-middleware-backtrace'';
  version = ''lack-20191007-git'';

  description = ''System lacks description'';

  deps = [ args."uiop" ];

  src = fetchurl {
    url = ''http://beta.quicklisp.org/archive/lack/2019-10-07/lack-20191007-git.tgz'';
    sha256 = ''1pjvsk1hc0n6aki393mg2z0dd0xwbkm4pmdph78jlk683158an5s'';
  };

  packageName = "lack-middleware-backtrace";

  asdFilesToKeep = [ "lack-middleware-backtrace.asd" ];
  overrides = x: x;
}
/* (SYSTEM lack-middleware-backtrace DESCRIPTION System lacks description
    SHA256 1pjvsk1hc0n6aki393mg2z0dd0xwbkm4pmdph78jlk683158an5s URL
    http://beta.quicklisp.org/archive/lack/2019-10-07/lack-20191007-git.tgz MD5
    bce7a6b5aefb5bfd3fbeb782dda7748f NAME lack-middleware-backtrace FILENAME
    lack-middleware-backtrace DEPS ((NAME uiop FILENAME uiop)) DEPENDENCIES
    (uiop) VERSION lack-20191007-git SIBLINGS
    (lack-component lack-middleware-accesslog lack-middleware-auth-basic
     lack-middleware-csrf lack-middleware-mount lack-middleware-session
     lack-middleware-static lack-request lack-response lack-session-store-dbi
     lack-session-store-redis lack-test lack-util-writer-stream lack-util lack
     t-lack-component t-lack-middleware-accesslog t-lack-middleware-auth-basic
     t-lack-middleware-backtrace t-lack-middleware-csrf t-lack-middleware-mount
     t-lack-middleware-session t-lack-middleware-static t-lack-request
     t-lack-session-store-dbi t-lack-session-store-redis t-lack-util t-lack)
    PARASITES NIL) */
