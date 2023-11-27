{ buildPythonPackage
, fetchFromGitHub
, lib
, numpy
, pygame
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "pgzero";
  version = "1.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lordmauve";
    repo = "pgzero";
    rev = version;
    hash = "sha256-O3fQCs8lwyF42N2vmlJvkk/UqsNS3T4geDiHZj9lS3M=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [ numpy pygame ];

  pythonImportsCheck = [ "pgzero" ];

  meta = with lib; {
    description = "A zero-boilerplate games programming framework for Python 3, based on Pygame";
    homepage = "https://github.com/lordmauve/pgzero";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ ];
  };
}
