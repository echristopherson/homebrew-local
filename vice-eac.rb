class ViceEac < Formula
  desc "Versatile Commodore Emulator"
  homepage "https://vice-emu.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/vice-emu/releases/vice-3.0.tar.gz"
  sha256 "bc56811381920d43ab5f2f85a5e08f21ab5bdf6190dd5dfe9f500a745d14972b"

  head "svn://svn.code.sf.net/p/vice-emu/code/trunk/vice"

  bottle do
    cellar :any
    sha256 "3043ee3ba75f5852712903d920df39b481058c3977b4bc32a64981f5a81642f1" => :sierra
    sha256 "40f96924355b684e8a99118615bcd62ef16c9e723a18c3605b861036c11a577e" => :el_capitan
    sha256 "a3bc56a1ef73d95b55f1be29e547dbc83d049a4b7521db92a803f69559cab39d" => :yosemite
  end

  option "with-sdl", "Use SDL instead of Cocoa user interface"
  option "with-memmap", "Use memmap support (for monitor)"

  depends_on "pkg-config" => :build
  depends_on "texinfo" => :build
  depends_on "yasm" => :build
  depends_on "flac"
  depends_on "giflib"
  depends_on "jpeg"
  depends_on "lame"
  depends_on "libogg"
  depends_on "libpng"
  depends_on "libvorbis"
  depends_on "portaudio"
  depends_on "xz"

  depends_on "automake" => :build if build.head?
  depends_on "autoconf" => :build if build.head?
  depends_on "sdl" if build.with? "sdl"

  # needed to avoid Makefile errors with the vendored ffmpeg 2.4.2
  resource "make" do
    url "https://ftpmirror.gnu.org/make/make-4.2.1.tar.bz2"
    mirror "https://ftp.gnu.org/gnu/make/make-4.2.1.tar.bz2"
    sha256 "d6e262bf3601b42d2b1e4ef8310029e1dcf20083c5446b4b7aa67081fdffc589"
  end

  def install
    resource("make").stage do
      system "./configure", "--prefix=#{buildpath}/vendor/make",
                            "--disable-dependency-tracking"
      system "make", "install"
    end
    ENV.prepend_path "PATH", buildpath/"vendor/make/bin"
    ENV.refurbish_args # since "make" won't be the shim

    # Call autogen first, since we might be replacing text in configure later
    # (TODO: that was my old note for this block; but now it appears that I
    # always need to run autogen.sh when building from HEAD.)
    if build.head?
      system "./autogen.sh"
    end

    if OS.mac?
      # Fix undefined symbol errors for _Gestalt, _VDADecoderCreate, _iconv
      # among others.
      ENV["LIBS"] = "-framework CoreServices -framework VideoDecodeAcceleration -framework CoreVideo -liconv"
    end

    # Use Cocoa instead of X
    # Use a static lame, otherwise Vice is hard-coded to look in
    # /opt for the library.
    configure_options = [ "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-static-ffmpeg",
                          "--enable-static-lame", ]
    configure_options << "--without-x" if OS.mac?

    if build.with? "sdl"
      # Last I knew SDL2 UI wasn't quite ready yet, but that was a while ago.
      #configure_options << "--enable-sdlui2" << "--with-sdlsound"
      configure_options << "--enable-sdlui" << "--with-sdlsound"
    else
      if OS.mac?
        # WIP according to upstread
        #configure_options << "--enable-native-gtkui3"
        configure_options << "--with-cocoa"
      else
        # WIP according to upstread
        #configure_options << "--enable-native-gtkui3"
        configure_options << "--enable-gnomeui3"
      end
    end

    if build.with? "memmap"
      configure_options << " --with-memmap"
    end

    system "./configure", *configure_options
    system "make"

    system "make"
    if OS.mac?
      system "make", "bindist"
      prefix.install Dir["vice-macosx-*/*"]
      bin.install_symlink Dir[prefix/"tools/*"]
    else
      system "make", "install"
    end
  end

  if OS.mac?
    def caveats; <<-EOS.undent
      Cocoa apps for these emulators have been installed to #{prefix}.
    EOS
    end
  end

  test do
    assert_match "Usage", shell_output("#{bin}/petcat -help", 1)
  end
end
