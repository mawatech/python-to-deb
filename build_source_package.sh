#!/bin/bash

set -x

ox_step_handle_arguments() {
  OX_PYTHON_NAME=$(basename "$1")

  export OX_SCRIPTDIR
  OX_SCRIPTDIR=$(cd "$(dirname "$0")"; pwd)
  export OX_PKG_BUILDER_DIR=$OX_SCRIPTDIR/packages/$OX_PYTHON_NAME

  OX_PKG_BUILDER_SCRIPT=$OX_PKG_BUILDER_DIR/build.sh

}

ox_step_setup_variables() {
  : "${OX_TOPDIR:="$HOME/.stdeb-build"}"

  OX_SOURCE_PKGDIR="$OX_SCRIPTDIR/source_packages"
  
  OX_PKG_BUILDDIR=$OX_TOPDIR/$OX_PYTHON_NAME
  OX_PKG_DEB_DISTDIR="$OX_PKG_BUILDDIR/deb_dist"
  
  OX_PACKAGE_NAME=""
  OX_PACKAGE_VERSION=""
  OX_COMMON_DEB_BUILD_DEPENDS_ARGS="dh-python"
  OX_COMMON_RPM_BUILD_DEPENDS_ARGS=""
  OX_EXTRA_BUILD_DEPENDS_ARGS=""
  OX_COMMON_DEPENDS_ARGS=""
  OX_EXTRA_DEPENDS_ARGS=""
  OX_SETUP_ENV_VARS="DEB_BUILD_OPTIONS=nocheck"
  OX_DEBIAN_EPOCH=""

  OX_PYTHON="python"
  OX_DSC_CREATE_COMMAND="setup.py --command-packages=stdeb.command sdist_dsc"
  OX_DEB_CREATE_SUFFIX="bdist_deb"
  OX_SPEC_CREATE_COMMAND="setup.py bdist_rpm --dist-dir $OX_PKG_DEB_DISTDIR --spec-only"
}

ox_step_start_build() {
  # shellcheck source=/dev/null
  source "$OX_PKG_BUILDER_SCRIPT"

  # Cleanup old state:
  rm -Rf "$OX_PKG_BUILDDIR"

  # Ensure folders present
  mkdir -p "$OX_SOURCE_PKGDIR" \
     "$OX_PKG_BUILDDIR"
}

ox_step_extract_package() {
  cd "$OX_PKG_BUILDDIR"

  if [ -n "$OX_PACKAGE_VERSION" ]; then
    pypi-download "$OX_PYTHON_NAME" --release "$OX_PACKAGE_VERSION" --allow-unsafe-download
  else
    pypi-download --allow-unsafe-download "$OX_PYTHON_NAME"
  fi

  OX_TAR_GZ_NAME=$(ls *.tar.gz)

  tar xvzf "$OX_TAR_GZ_NAME" --strip-components=1
}

ox_step_configure () {
  if [ -z "$OX_PACKAGE_NAME" ]; then
    OX_PACKAGE_NAME="python-$OX_PYTHON_NAME"
  fi
}

ox_step_create_debian() {
  cd "$OX_PKG_BUILDDIR"
  #py2dsc -x "$CONFIG_FILE" "$TAR_GZ_NAME"
  #py2dsc-deb -x "$CONFIG_FILE" "$TAR_GZ_NAME"
  #sudo pypi-install "$PKG_NAME" -x "$CONFIG_FILE"

  if [ -n "$OX_SETUP_ENV_VARS" ]; then
    OX_DSC_CREATE_COMMAND+=" --setup-env-vars $OX_SETUP_ENV_VARS"
  fi

  local BUILD_DEPENDS_ARGS=""
  if [ -n "$OX_COMMON_DEB_BUILD_DEPENDS_ARGS" ]; then
    BUILD_DEPENDS_ARGS+=" --build-depends $OX_COMMON_DEB_BUILD_DEPENDS_ARGS"
  fi

  if [ -n "$OX_EXTRA_BUILD_DEPENDS_ARGS" ]; then
    if [ -n "$OX_COMMON_DEB_BUILD_DEPENDS_ARGS" ]; then
      BUILD_DEPENDS_ARGS+=",$OX_EXTRA_BUILD_DEPENDS_ARGS"
    else
      BUILD_DEPENDS_ARGS+=" --build-depends $OX_EXTRA_BUILD_DEPENDS_ARGS"
    fi
  fi

  local DEPENDS_ARGS=""
  if [ -n "$OX_COMMON_DEPENDS_ARGS" ]; then
    DEPENDS_ARGS+=" --depends $OX_COMMON_DEPENDS_ARGS"
  fi

  if [ -n "$OX_EXTRA_DEPENDS_ARGS" ]; then
    if [ -n "$OX_COMMON_DEPENDS_ARGS" ]; then
      DEPENDS_ARGS+=",$OX_EXTRA_DEPENDS_ARGS"
    else
      DEPENDS_ARGS+=" --depends $OX_EXTRA_DEPENDS_ARGS"
    fi
  fi

  OX_DSC_CREATE_COMMAND+=" --package $OX_PACKAGE_NAME"

  if [ -n "$OX_DEBIAN_EPOCH" ]; then
    OX_DSC_CREATE_COMMAND+=" --epoch $OX_DEBIAN_EPOCH"
  fi

  python $OX_DSC_CREATE_COMMAND \
    $DEPENDS_ARGS \
    $BUILD_DEPENDS_ARGS \
    bdist_deb

}

ox_step_collect_deb_source_packages() {
  OX_SOURCE_TARGETDIR=$OX_SOURCE_PKGDIR/$OX_PACKAGE_NAME
  mkdir -p "$OX_SOURCE_TARGETDIR"
  DEBIAN_TAR=$(ls $OX_PKG_DEB_DISTDIR/*.tar.xz)
  ORIG_TAR=$(ls $OX_PKG_DEB_DISTDIR/*.tar.gz)
  DSC=$(ls $OX_PKG_DEB_DISTDIR/*.dsc)
  cp "$DEBIAN_TAR" "$OX_SOURCE_TARGETDIR"
  cp "$ORIG_TAR" "$OX_SOURCE_TARGETDIR"
  cp "$DSC" "$OX_SOURCE_TARGETDIR"
}

ox_step_install_deb_package() {
  DEB_FILE=$(ls $OX_PKG_DEB_DISTDIR/*.deb)
  sudo dpkg -i "$DEB_FILE"
  sudo apt-get -fy install
}

ox_step_create_spec_file() (
  cd "$OX_PKG_BUILDDIR"

  local BUILD_REQUIRES_ARGS=""
  if [ -n "$OX_COMMON_RPM_BUILD_DEPENDS_ARGS" ]; then
    BUILD_REQUIRES_ARGS+=" --build-requires $OX_COMMON_RPM_BUILD_DEPENDS_ARGS"
  fi

  if [ -n "$OX_EXTRA_BUILD_DEPENDS_ARGS" ]; then
    if [ -n "$OX_COMMON_RPM_BUILD_DEPENDS_ARGS" ]; then
      BUILD_REQUIRES_ARGS+=",$OX_EXTRA_BUILD_DEPENDS_ARGS"
    else
      BUILD_REQUIRES_ARGS+=" --build-requires $OX_EXTRA_BUILD_DEPENDS_ARGS"
    fi
  fi

  local REQUIRES_ARGS=""
  if [ -n "$OX_COMMON_DEPENDS_ARGS" ]; then
    REQUIRES_ARGS+=" --requires $OX_COMMON_DEPENDS_ARGS"
  fi

  if [ -n "$OX_EXTRA_DEPENDS_ARGS" ]; then
    if [ -n "$OX_COMMON_DEPENDS_ARGS" ]; then
      REQUIRES_ARGS+=",$OX_EXTRA_DEPENDS_ARGS"
    else
      REQUIRES_ARGS+=" --requires $OX_EXTRA_DEPENDS_ARGS"
    fi
  fi

  $OX_PYTHON $OX_SPEC_CREATE_COMMAND \
      $BUILD_REQUIRES_ARGS \
      $REQUIRES_ARGS

  cd "$OX_PKG_DEB_DISTDIR"


  sed -i "s/Source0: %{name}-%{unmangled_version}.tar.gz/Source0: $(basename $ORIG_TAR)/" "$OX_PYTHON_NAME.spec"
  #sed -i "s/Name: %{name}/Name: $OX_PACKAGE_NAME/" "$OX_PYTHON_NAME.spec"
)

ox_step_collect_rpm_source_packages() {
  OX_SOURCE_TARGETDIR=$OX_SOURCE_PKGDIR/$OX_PACKAGE_NAME
  mkdir -p "$OX_SOURCE_TARGETDIR"
  SPEC=$(ls $OX_PKG_DEB_DISTDIR/*.spec)
  cp "$SPEC" "$OX_SOURCE_TARGETDIR"
}

ox_step_cleanup () {
  rm -rf "$OX_PKG_BUILDDIR"
}

ox_step_osc_add () {
  osc add "$OX_PACKAGE_NAME"
}

ox_step_osc_commit() {
  osc ci -n "$OX_PACKAGE_NAME"
}

ox_step_handle_arguments "$@"
ox_step_setup_variables
ox_step_start_build
ox_step_extract_package
ox_step_configure
cd "$OX_PKG_BUILDDIR"
ox_step_create_debian
cd "$OX_PKG_BUILDDIR"
ox_step_collect_deb_source_packages
cd "$OX_PKG_BUILDDIR"
ox_step_install_deb_package
#cd "$OX_PKG_BUILDDIR"
#ox_step_create_spec_file
#ox_step_collect_rpm_source_packages
cd "$OX_SOURCE_PKGDIR"
ox_step_osc_add
ox_step_osc_commit
