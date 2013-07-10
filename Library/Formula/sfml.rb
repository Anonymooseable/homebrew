require 'formula'

class Sfml < Formula
  homepage 'http://www.sfml-dev.org'
  url 'http://www.sfml-dev.org/download/sfml/2.0/SFML-2.0-sources.zip'
  sha1 'ff8cf290f49e1a1d8517a4a344e9214139da462f'
  head 'https://github.com/LaurentGomila/SFML.git'

  option :universal
  option 'build-examples', 'Build Examples'

  depends_on 'cmake' => :build
  depends_on 'freetype'
  depends_on 'libsndfile'
  depends_on 'jpeg'
  depends_on 'glew'

  def install
    ENV.universal_binary if build.include? 'universal'

    args = std_cmake_args
    args.delete '-DCMAKE_BUILD_TYPE=None'
    args.push '-DCMAKE_BUILD_TYPE=Release', '-DINSTALL_EXTERNAL_LIBS=FALSE'

    args << '-DSFML_BUILD_EXAMPLES=TRUE'            if build.include? 'build-examples'
    args.push '-DSFML_BUILD_FRAMEWORKS=FALSE', '-DSFML_USE_EXTLIBS=FALSE'

    system 'cmake', '.', *args
    system 'make install'
  end

  def caveats
    msg = ""
    msg = <<-EOS.undent
      The CMake find-module is available at #{opt_prefix}/share/sfml/cmake/Modules/FindSFML.cmake
      You may need to copy it to #{HOMEBREW_PREFIX}/share/cmake/Modules
    EOS
    msg.concat examples_caveats if build.include? 'build-examples'

    msg
  end
  def patches
    DATA
  end
  private
    def examples_caveats; <<-EOS.undent
      The examples were installed to:
        #{opt_prefix}/share/sfml/examples
      EOS
    end
end

__END__
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 959a403..ab45c7f 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -39,7 +39,10 @@ sfml_set_option(SFML_BUILD_DOC FALSE BOOL "TRUE to generate the API documentatio
 # Mac OS X specific options
 if(MACOSX)
     # add an option to build frameworks instead of dylibs (release only)
-    sfml_set_option(SFML_BUILD_FRAMEWORKS FALSE BOOL "TRUE to build SFML as frameworks libraries (release only), FALSE to build according to BUILD_SHARED_LIBS")
+    sfml_set_option(SFML_BUILD_FRAMEWORKS FALSE BOOL "TRUE to build SFML as frameworks libraries (release only), FALSE to build according to BUILD_SHARED_LIBS")
+
+    # add an option to use system libraries rather than bundled extlibs
+    sfml_set_option(SFML_USE_EXTLIBS TRUE BOOL "TRUE to use versions of freetype, sndfile, GLEW and libjpeg bundled with SFML (and install them), FALSE to find versions already installed on the system")
     
     # add an option to let the user specify a custom directory for frameworks installation (SFML, sndfile, ...)
     sfml_set_option(CMAKE_INSTALL_FRAMEWORK_PREFIX "/Library/Frameworks" STRING "Frameworks installation directory")
@@ -198,10 +201,11 @@ if(WINDOWS)
         install(FILES extlibs/bin/x64/libsndfile-1.dll DESTINATION bin)
         install(FILES extlibs/bin/x64/openal32.dll DESTINATION bin)
     endif()
-elseif(MACOSX)
-    install(DIRECTORY extlibs/libs-osx/Frameworks/sndfile.framework DESTINATION ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
-    install(DIRECTORY extlibs/libs-osx/Frameworks/freetype.framework DESTINATION ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
-
+elseif(MACOSX)
+    if (SFML_USE_EXTLIBS)
+        install(DIRECTORY extlibs/libs-osx/Frameworks/sndfile.framework DESTINATION ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
+        install(DIRECTORY extlibs/libs-osx/Frameworks/freetype.framework DESTINATION ${CMAKE_INSTALL_FRAMEWORK_PREFIX})
+    endif ()
     if(SFML_INSTALL_XCODE4_TEMPLATES)
         install(DIRECTORY tools/xcode/templates/SFML DESTINATION /Library/Developer/Xcode/Templates)
     endif()
diff --git a/src/SFML/Audio/CMakeLists.txt b/src/SFML/Audio/CMakeLists.txt
index 818b9b6..cb81e75 100644
--- a/src/SFML/Audio/CMakeLists.txt
+++ b/src/SFML/Audio/CMakeLists.txt
@@ -31,10 +31,10 @@ set(SRC
 source_group("" FILES ${SRC})
 
 # let CMake know about our additional audio libraries paths (on Windows and OSX)
-if(WINDOWS)
+if(WINDOWS AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/AL")
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libsndfile/windows")
-elseif (MACOSX)
+elseif (MACOSX AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libsndfile/osx")
     set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${PROJECT_SOURCE_DIR}/extlibs/libs-osx/Frameworks")
 endif()
diff --git a/src/SFML/CMakeLists.txt b/src/SFML/CMakeLists.txt
index a3fb4d9..10efc95 100644
--- a/src/SFML/CMakeLists.txt
+++ b/src/SFML/CMakeLists.txt
@@ -3,7 +3,7 @@
 include(${PROJECT_SOURCE_DIR}/cmake/Macros.cmake)
 
 # let CMake know about our additional libraries paths (on Windows and OS X)
-if (WINDOWS)
+if (WINDOWS AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers")
     if(COMPILER_GCC)
         if(ARCH_32BITS)
@@ -20,7 +20,7 @@ if (WINDOWS)
             set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${PROJECT_SOURCE_DIR}/extlibs/libs-msvc/x64")
         endif()
     endif()
-elseif(MACOSX)
+elseif(MACOSX AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers")
     set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${PROJECT_SOURCE_DIR}/extlibs/libs-osx/lib/")
 endif()
diff --git a/src/SFML/Graphics/CMakeLists.txt b/src/SFML/Graphics/CMakeLists.txt
index ba74b71..56c54db 100644
--- a/src/SFML/Graphics/CMakeLists.txt
+++ b/src/SFML/Graphics/CMakeLists.txt
@@ -84,14 +84,14 @@ set(STB_SRC
 source_group("stb_image" FILES ${STB_SRC})
 
 # let CMake know about our additional graphics libraries paths (on Windows and OSX)
-if(WINDOWS OR MACOSX)
+if(WINDOWS OR MACOSX AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/jpeg")
 endif()
 
-if(WINDOWS)
+if(WINDOWS AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libfreetype/windows")
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libfreetype/windows/freetype")
-elseif(MACOSX)
+elseif(MACOSX AND SFML_USE_EXTLIBS)
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libfreetype/osx")
     set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${PROJECT_SOURCE_DIR}/extlibs/headers/libfreetype/osx/freetype2")
     set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${PROJECT_SOURCE_DIR}/extlibs/libs-osx/Frameworks")
