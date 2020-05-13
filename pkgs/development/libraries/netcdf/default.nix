{ stdenv
, fetchurl
, hdf5
, m4
, curl # for DAP
}:
let
  mpiSupport = hdf5.mpiSupport;
  mpi = hdf5.mpi;
in
stdenv.mkDerivation rec {
  pname = "netcdf";
  version = "4.7.3";

  src = fetchurl {
    url = "https://www.unidata.ucar.edu/downloads/netcdf/ftp/${pname}-c-${version}.tar.gz";
    sha256 = "12s4w2s96p51hlsa81lw92w56rdx8i3mk21pz2ydwcamw579z34f";
  };

  postPatch = ''
    patchShebangs .

    # this test requires the net
    for a in ncdap_test/Makefile.am ncdap_test/Makefile.in; do
      substituteInPlace $a --replace testurl.sh " "
    done
  '';

  nativeBuildInputs = [ m4 ];
  buildInputs = [ hdf5 curl mpi ];

  passthru = {
    mpiSupport = mpiSupport;
    inherit mpi;
  };

  configureFlags = [
    "--enable-netcdf-4"
    "--enable-dap"
    "--enable-shared"
    "--disable-dap-remote-tests"
  ]
  ++ (stdenv.lib.optionals mpiSupport [ "--enable-parallel-tests" "CC=${mpi}/bin/mpicc" ]);

  doCheck = !mpiSupport;

  meta = {
    description = "Libraries for the Unidata network Common Data Format";
    platforms = stdenv.lib.platforms.unix;
    homepage = https://www.unidata.ucar.edu/software/netcdf/;
    license = {
      url = https://www.unidata.ucar.edu/software/netcdf/docs/copyright.html;
    };
  };
}
