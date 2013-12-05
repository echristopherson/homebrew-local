require 'formula'

class Freeciv < Formula
  homepage 'http://freeciv.wikia.com'
  url 'http://downloads.sourceforge.net/project/freeciv/Freeciv%202.3/2.3.1/freeciv-2.3.1.tar.bz2'
  sha1 '9d9ee9f48f4c945fc6525139d340443d5a25aac4'
  head 'svn://svn.gna.org/svn/freeciv/trunk'

  option 'disable-nls', 'Disable NLS support'

  depends_on 'pkg-config' => :build
  depends_on 'gtk+'
  depends_on :x11
  depends_on 'gettext' unless build.include? 'disable-nls'

  def install
    args = ["--disable-debug", "--disable-dependency-tracking",
            "--prefix=#{prefix}", "--enable-client=gtk2"]

    unless build.include? 'disable-nls'
      gettext = Formula.factory('gettext')
      args << "CFLAGS=-I#{gettext.include}"
      args << "LDFLAGS=-L#{gettext.lib}"
    end

    system "./configure", *args
    system "make install"
  end

  def test
    system "#{bin}/freeciv-server -v"
  end
end
