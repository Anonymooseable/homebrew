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

  def install
    ENV.universal_binary if build.include? 'universal'

    args = std_cmake_args
    args.delete '-DCMAKE_BUILD_TYPE=None'
    args.push '-DCMAKE_BUILD_TYPE=Release', '-DINSTALL_EXTERNAL_LIBS=FALSE'

    args << '-DSFML_BUILD_EXAMPLES=TRUE'            if build.include? 'build-examples'
    args.push '-DSFML_BUILD_FRAMEWORKS=FALSE'

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

  private
    def examples_caveats; <<-EOS.undent
      The examples were installed to:
        #{opt_prefix}/share/sfml/examples
      EOS
    end
end
