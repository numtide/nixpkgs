{ stdenv
, fetchFromGitLab
, meson
, ninja
, pkg-config
, python3Packages
, vulkan-headers
, vulkan-loader
, shaderc
, glslang
, lcms2
, epoxy
}:

stdenv.mkDerivation rec {
  pname = "libplacebo";
  version = "2.72.0";

  src = fetchFromGitLab {
    domain = "code.videolan.org";
    owner = "videolan";
    repo = pname;
    rev = "v${version}";
    sha256 = "1yhf9xyxdawbihsx89dpjlac800wrmpwx63rphad2nj225y9q40f";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3Packages.Mako
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    shaderc
    glslang
    lcms2
    epoxy
  ];

  mesonFlags = [
    "-Dvulkan-registry=${vulkan-headers}/share/vulkan/registry/vk.xml"
  ];

  meta = with stdenv.lib; {
    description = "Reusable library for GPU-accelerated video/image rendering primitives";
    longDescription = ''
      Reusable library for GPU-accelerated image/view processing primitives and
      shaders, as well a batteries-included, extensible, high-quality rendering
      pipeline (similar to mpv's vo_gpu). Supports Vulkan, OpenGL and Metal (via
      MoltenVK).
    '';
    homepage = "https://code.videolan.org/videolan/libplacebo";
    changelog = "https://code.videolan.org/videolan/libplacebo/-/tags/v${version}";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ primeos tadeokondrak ];
    platforms = platforms.all;
  };
}
