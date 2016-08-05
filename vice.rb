class Vice < Formula
  desc "Versatile Commodore Emulator"
  homepage "http://vice-emu.sourceforge.net/"
  url "http://www.zimmers.net/anonftp/pub/cbm/crossplatform/emulators/VICE/vice-2.4.tar.gz"
  sha256 "ff8b8d5f0f497d1f8e75b95bbc4204993a789284a08a8a59ba727ad81dcace10"
  revision 2

  head "svn://svn.code.sf.net/p/vice-emu/code/trunk/vice"

  option "with-sdl", "Use SDL instead of Cocoa user interface"
  option "with-memmap", "Use memmap support (for monitor)"

  bottle do
    cellar :any
    sha256 "1734a97e9772b5b42cd917628094240b24ddcf21e68910e8e1107274a1f9275a" => :el_capitan
    sha256 "b64f33472ea5655c1aac3795b79d99b14738c28642c0cf21d9708441d02323ef" => :yosemite
    sha256 "05446f9614d5ee6170cd2d323ad24289a0312ac42a5f2ec575200036513731b1" => :mavericks
    sha256 "de32b3004dbc9a1dad21a546c983ba55d3559eae78f898a54be96c8f2c278b3b" => :mountain_lion
  end

  depends_on "pkg-config" => :build
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "giflib"
  depends_on "lame" => :optional
  depends_on "sdl" if build.with? "sdl"

  fails_with :llvm do
    build 2335
  end

  def install
    # Use Cocoa or SDL instead of X
    # Use a static lame, otherwise Vice is hard-coded to look in
    # /opt for the library.
    configure_options = [ "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--without-x",
                          "--enable-static-lame",
                          # VICE can't compile against FFMPEG newer than 0.11:
                          # https://sourceforge.net/p/vice-emu/bugs/341/
                          "--disable-ffmpeg" ]
    if build.with? "sdl"
      configure_options << "--enable-sdlui" << "--with-sdlsound"
      # Upstream source assumes presence of
      # /Library/Frameworks/SDL.framework/Headers
      inreplace "configure" do |configure|
        configure.gsub! "/Library/Frameworks/SDL.framework/Headers", "/usr/local/include/SDL"
        configure.gsub! "-framework SDL", "-lSDL"
      end
      # Upstream forgot to point this to its new location?
      inreplace "src/arch/sdl/archdep_unix.c", '#include "../unix/macosx/platform_macosx.c"', '#include "../../platform/platform_macosx.c"'
    else
      configure_options << "--with-cocoa"
    end

    if build.with? "memmap"
      configure_options << " --with-memmap"
    end

    system "./configure", *configure_options
    system "make"
    system "make", "bindist"
    prefix.install Dir["vice-macosx-*/*"]
    bin.install_symlink Dir[prefix/"tools/*"]
  end

  def caveats; <<-EOS.undent
    Cocoa apps for these emulators have been installed to #{prefix}.
  EOS
  end
end
