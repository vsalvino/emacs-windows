<#
.SYNOPSIS
Builds a customized version of emacs.
#>

# Enter mingw64
$env:CHERE_INVOKING = 'yes'  # Preserve the current working directory
$env:MSYSTEM = 'MINGW64'  # Start a 64 bit Mingw environment

# File paths, swapped to unix format.
$win_srcdir = $($PSScriptRoot)
$win_blddir = $(Join-Path $win_srcdir "_build")
$unx_srcdir = $win_srcdir -replace "\\","/" -replace "C\:","/c"
$unx_blddir = $win_blddir -replace "\\","/" -replace "C\:","/c"
$unx_installdir = "/c/Program Files/Emacs"

# Clean build dir
#Remove-Item -Recurse -Force -ErrorAction Ignore -Path $win_blddir
#New-Item -Type Directory -Path $win_blddir
#& "C:\msys64\usr\bin\bash" -lc "make maintainer-clean";

# Refresh code
git fetch upstream
git rebase upstream/master

# Refresh dependencies
& "C:\msys64\usr\bin\bash" -lc "pacman -Syuu";

# Setup
& "C:\msys64\usr\bin\bash" -lc "./autogen.sh";
& "C:\msys64\usr\bin\bash" -lc "
  cd ${unx_blddir};
  ${unx_srcdir}/configure \
    --prefix=${unx_blddir} \
    --enable-link-time-optimization \
    --without-dbus \
    --without-gconf \
    --without-gpm \
    --without-libgmp \
    --without-libsystemd \
    --without-m17n-flt \
    --without-pop \
    --without-selinux \
    --without-xdbe \
    --without-xft \
    --with-file-notification=w32 \
    --with-json \
    --with-w32 \
    CFLAGS='-O2 -g0';
"

# Compile
& "C:\msys64\usr\bin\bash" -lc "make -j4"

# Install
& "C:\msys64\usr\bin\bash" -lc "
  echo 'Installing...';
  make install prefix='${unx_installdir}' > /dev/null;
  echo 'Done.';
"

# Bundle mingw dependency DLLs with the executables.
& "C:\msys64\usr\bin\bash" -lc "
  cd ${unx_blddir};
  wget -O mingw-bundledlls https://raw.githubusercontent.com/mpreisler/mingw-bundledlls/master/mingw-bundledlls;
  chmod +x mingw-bundledlls;
  ./mingw-bundledlls --copy '${unx_installdir}/bin/emacs.exe';
"
