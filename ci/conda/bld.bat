@echo on
setlocal EnableDelayedExpansion

:: Windows counterpart of build.sh, see there for the rationale of each step.
:: The main difference is that IDSDef.xml is passed to CMake with -D IDSDEF
:: instead of through an `idsinfo` stand-in (CMake looks for idsinfo.exe).

:: 1. Generate IDSDef.xml from the Data Dictionary sources
pushd data-dictionary
java -cp "%CLASSPATH%" net.sf.saxon.Transform ^
    -xsl:dd_data_dictionary.xml.xsl ^
    -s:dd_data_dictionary.xml.xsd ^
    -o:IDSDef.xml ^
    DD_GIT_DESCRIBE=%DD_VERSION%
if errorlevel 1 exit 1
popd

:: Assemble the layout expected by ALBuildDataDictionary.cmake:
:: IDSDef.xml with the identifier XML files in per-IDS subdirectories next to it
mkdir dd
copy data-dictionary\IDSDef.xml dd\
if errorlevel 1 exit 1
for /d %%D in (data-dictionary\schemas\*) do (
    if exist "%%D\*_identifier.xml" (
        mkdir "dd\%%~nxD"
        copy "%%D\*_identifier.xml" "dd\%%~nxD\" > nul
        if errorlevel 1 exit 1
    )
)
set "IDSDEF=%SRC_DIR:\=/%/dd/IDSDef.xml"

:: 2. Saxon-HE based replacement for the saxonche-based xsltproc.py
copy /y "%RECIPE_DIR%\xsltproc.py" common\xsltproc.py
if errorlevel 1 exit 1

:: 3. Pre-create the venv expected at <builddir>/dd_build_env so that the build
::    system does not attempt to create it and `pip install saxonche`
mkdir build
python -m venv build\dd_build_env
if errorlevel 1 exit 1

:: The al-core.pc file from libimas-core embeds GNU-ld-only flags
:: ('-Wl,--defsym,AL_VER_<version>=0' and '-Wl,-rpath,...'), which the MSVC
:: linker rejects: strip them from the pkg-config file in the host environment.
:: This is a build-time change only: files pre-existing in the host prefix
:: are not packaged, so the installed libimas-core package is unaffected.
python -c "import pathlib, re; p = pathlib.Path(r'%LIBRARY_LIB%\pkgconfig\al-core.pc'); p.write_text(re.sub(r'-Wl,\S+ ?', '', p.read_text()))"
if errorlevel 1 exit 1
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig"

:: Report the toolchain, for debugging
where cl flang flang-new java pkg-config
echo FC=%FC% CC=%CC% CXX=%CXX%
pkg-config --cflags --libs al-core

cmake %CMAKE_ARGS% ^
    -G Ninja ^
    -B build ^
    -S "%SRC_DIR%" ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -D CMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
    -D IDSDEF="%IDSDEF%" ^
    -D AL_DOWNLOAD_DEPENDENCIES=OFF ^
    -D AL_DEVELOPMENT_LAYOUT=OFF ^
    -D AL_PLUGINS=OFF ^
    -D AL_TESTS=OFF ^
    -D AL_EXAMPLES=OFF
if errorlevel 1 exit 1

cmake --build build --target install
if errorlevel 1 exit 1

:: Our own generated pkg-config files embed the same GNU-ld-only flags
for %%F in (al-fortran.pc al-fortran-%DD_VERSION%.pc al-identifiers-fortran.pc imas-fortran.pc imas-fortran-%DD_VERSION%.pc imas-identifiers-fortran.pc) do (
    python -c "import pathlib, re; p = pathlib.Path(r'%LIBRARY_LIB%\pkgconfig\%%F'); p.write_text(re.sub(r'-Wl,\S+ ?', '', p.read_text()))"
    if errorlevel 1 exit 1
)
