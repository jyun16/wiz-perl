package MobileTmpl::Controller::Mobile;

use Wiz::Noose;

no warnings 'uninitialized';

extends qw(
    Wiz::Web::Framework::Controller::Root
);

use File::Temp;
use File::stat;
use File::Basename;

use HTTP::MobileAgent;
use HTTP::MobileUserID;

use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile;
use HTTP::MobileAgent::Plugin::Charset;

use Net::CIDR::MobileJP;
use Cache::Memcached::Fast;
use Data::Dumper;

sub index {
    my $self = shift;
    my ($c) = @_;
    my $base = $c->req->base;
    $c->res->body(<<"EOS");
<html>
<head>
<title></title>
</head>
<body>
* <a href="${base}mobile_fw/">MobileFW</a><br>
* <a href="${base}mobile/qr">QR code generator</a><br>
* <a href="${base}mobile/uid">Check UID</a><br>
* <a href="${base}mobile/cidr">Check CIDR</a><br>
* <a href="${base}mobile/emo">Emo</a><br>
* <a href="${base}mobile/upload">Upload</a><br>
</body>
</html>
EOS
}

sub emo {
    my $self = shift;
    my ($c) = @_;
    my $agent = HTTP::MobileAgent->new;
    my $agent_name = $agent->name;
    my $encoding = $agent->encoding;
    my $charset = $encoding =~ /sjis/ ? 'shift_jis' : 'utf-8';
    my ($display, $width, $height, $depth) = ();
    unless ($agent->is_non_mobile) {
        $display = $agent->display;
        ($width, $height) = $display->size;
        $depth = $display->color ? $display->depth : '';
    }
    my $html = <<EOS;
<!DOCTYPE html PUBLC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<body>
<br>
Name: $agent_name<br>
Encoding: $encoding<br>
Width: $width<br>
Height: $height<br>
Depth: $depth<br>
<br>
\x{E63E}<br>
\x{E63F}<br>
\x{E640}<br>
\x{E641}<br>
\x{E642}<br>
\x{E643}<br>
\x{E644}<br>
\x{E645}<br>
\x{E646}<br>
\x{E647}<br>
\x{E648}<br>
\x{E649}<br>
\x{E64A}<br>
\x{E64B}<br>
\x{E64C}<br>
\x{E64D}<br>
\x{E64E}<br>
\x{E64F}<br>
\x{E650}<br>
\x{E651}<br>
\x{E652}<br>
\x{E653}<br>
\x{E654}<br>
\x{E655}<br>
\x{E656}<br>
\x{E657}<br>
\x{E658}<br>
\x{E659}<br>
\x{E65A}<br>
\x{E65B}<br>
\x{E65C}<br>
\x{E65D}<br>
\x{E65E}<br>
\x{E65F}<br>
\x{E660}<br>
\x{E661}<br>
\x{E662}<br>
\x{E663}<br>
\x{E664}<br>
\x{E665}<br>
\x{E666}<br>
\x{E667}<br>
\x{E668}<br>
\x{E669}<br>
\x{E66A}<br>
\x{E66B}<br>
\x{E66C}<br>
\x{E66D}<br>
\x{E66E}<br>
\x{E66F}<br>
\x{E670}<br>
\x{E671}<br>
\x{E672}<br>
\x{E673}<br>
\x{E674}<br>
\x{E675}<br>
\x{E676}<br>
\x{E677}<br>
\x{E678}<br>
\x{E679}<br>
\x{E67A}<br>
\x{E67B}<br>
\x{E67C}<br>
\x{E67D}<br>
\x{E67E}<br>
\x{E67F}<br>
\x{E680}<br>
\x{E681}<br>
\x{E682}<br>
\x{E683}<br>
\x{E684}<br>
\x{E685}<br>
\x{E686}<br>
\x{E687}<br>
\x{E688}<br>
\x{E689}<br>
\x{E68A}<br>
\x{E68B}<br>
\x{E68C}<br>
\x{E68D}<br>
\x{E68E}<br>
\x{E68F}<br>
\x{E690}<br>
\x{E691}<br>
\x{E692}<br>
\x{E693}<br>
\x{E694}<br>
\x{E695}<br>
\x{E696}<br>
\x{E697}<br>
\x{E698}<br>
\x{E699}<br>
\x{E69A}<br>
\x{E69B}<br>
\x{E69C}<br>
\x{E69D}<br>
\x{E69E}<br>
\x{E69F}<br>
\x{E6A0}<br>
\x{E6A1}<br>
\x{E6A2}<br>
\x{E6A3}<br>
\x{E6A4}<br>
\x{E6A5}<br>
\x{E6CE}<br>
\x{E6CF}<br>
\x{E6D0}<br>
\x{E6D1}<br>
\x{E6D2}<br>
\x{E6D3}<br>
\x{E6D4}<br>
\x{E6D5}<br>
\x{E6D6}<br>
\x{E6D7}<br>
\x{E6D8}<br>
\x{E6D9}<br>
\x{E6DA}<br>
\x{E6DB}<br>
\x{E6DC}<br>
\x{E6DD}<br>
\x{E6DE}<br>
\x{E6DF}<br>
\x{E6E0}<br>
\x{E6E1}<br>
\x{E6E2}<br>
\x{E6E3}<br>
\x{E6E4}<br>
\x{E6E5}<br>
\x{E6E6}<br>
\x{E6E7}<br>
\x{E6E8}<br>
\x{E6E9}<br>
\x{E6EA}<br>
\x{E6EB}<br>
\x{E70B}<br>
\x{E6EC}<br>
\x{E6ED}<br>
\x{E6EE}<br>
\x{E6EF}<br>
\x{E6F0}<br>
\x{E6F1}<br>
\x{E6F2}<br>
\x{E6F3}<br>
\x{E6F4}<br>
\x{E6F5}<br>
\x{E6F6}<br>
\x{E6F7}<br>
\x{E6F8}<br>
\x{E6F9}<br>
\x{E6FA}<br>
\x{E6FB}<br>
\x{E6FC}<br>
\x{E6FD}<br>
\x{E6FE}<br>
\x{E6FF}<br>
\x{E700}<br>
\x{E701}<br>
\x{E702}<br>
\x{E703}<br>
\x{E704}<br>
\x{E705}<br>
\x{E706}<br>
\x{E707}<br>
\x{E708}<br>
\x{E709}<br>
\x{E70A}<br>
\x{E6AC}<br>
\x{E6AD}<br>
\x{E6AE}<br>
\x{E6B1}<br>
\x{E6B2}<br>
\x{E6B3}<br>
\x{E6B7}<br>
\x{E6B8}<br>
\x{E6B9}<br>
\x{E6BA}<br>
<br>
</body>
</html>
EOS
    $c->res->headers->content_type("text/html; charset=$charset");
    if ($agent->is_non_mobile) {
        $html =~ s{(\p{InMobileJPPictograms})}{
            my $char = Encode::JP::Mobile::Character->from_unicode(ord $1);
            sprintf '[%s]', $char->name;
        }ge;
        $html = encode($encoding, $html, Encode::JP::Mobile::FB_CHARACTER);
    }
    else {
        $html = encode($encoding, $html);
    }
    $c->res->body($html);
}

sub emoji {
    my $self = shift;
    my ($c) = @_;
    my $agent  = HTTP::MobileAgent->new;
    $c->stash->{agent} = $agent;
    $c->stash->{template} = $c->path_to('tmpl') . '/mobile/emoji.tt';
    $c->forward('Test::View::TT');
}

sub upload {
    my $self = shift;
    my ($c) = @_;
    if (my $u = $c->req->upload('file_data')) {
        if ($u->size > $c->config->{max_upload_file_size}) {
            $c->forward('error');
        }
        my $fn = $u->filename;
        my $f = $c->path_to("tmp/file/$fn");
        $u->size;
        unless ($u->link_to($f) || $u->copy_to($f)) {
            die qq|can't copy $fn to $f: $!|;
        }
        my $im = new Image::Magick;
        $im->Read($f);
        my ($width, $height) = $im->Get('width', 'height'); 
        $im->Resize(width => $width * 0.5, height => $height * 0.5); 
        $im->Write("jpeg:" . $c->path_to('tmp/file/t_' . $fn));
        eval "use Image::Resize;";
        $@ and die $@;
        my $ir = Image::Resize->new($f);
        my $gd = $ir->resize(100, 100);
        open my $file, '>', $c->path_to('tmp/file/t_' . $fn);
        print $file $gd->jpeg;
        close $file;
    }
    $c->stash->{template} = $c->path_to('tmpl') . '/mobile/upload.tt';
    $c->forward('Test::View::TT');
}

sub carrier_longname {
    my ($carrier) = @_;
    if ($carrier eq 'E') { return 'EZWeb'; }
    elsif ($carrier eq 'V') { return 'SoftBank'; }
    elsif ($carrier eq 'I') { return 'DoCoMo'; }
    elsif ($carrier eq 'H') { return 'AirH'; }
}

sub get_carrier_by_cidr {
    my ($c, $ip) = @_;
    my $memd = Cache::Memcached::Fast->new($c->config->{cidr}{memcached_conf});
    my $cidr = Net::CIDR::MobileJP->new($memd->get($c->config->{cidr}{data_key}));
    return $cidr->get_carrier($ip);
}

sub cidr {
    my $self = shift;
    my ($c) = @_;
    my $cidr = Net::CIDR::MobileJP->new($c->path_to('conf') . '/' . $c->config->{file}{cidr});
    my $ip = $c->req->address;
    my $carrier = get_carrier_by_cidr($c, $ip);
    # N = PC, E = EZWeb, I = DoCoMo, V = SoftBank, H = AirH
    my $res = <<EOS;
<html>
<head>
<title></title>
</head>
<body>
EOS
    if ($carrier eq 'N') { $res .= 'You are non mobile user.<br>'; }
    else { $res .= 'You are ' . carrier_longname($carrier) . ' user.<br>'; }
    $res .= <<EOS;
IP: $ip<br>
Carrier: $carrier<br>

</body>
</html>
EOS
    $c->res->body($res);
}

my %QRCODE_DEFAULT = (
    Ecc         => 'L',
    Version     => 6,
    ModuleSize  => 1,
);

sub qr {
    my $self = shift;
    my ($c) = @_;
    my $res = <<EOS;
<html>
<head>
<title></title>
</head>
<body>
<form method="get" action="./qrres">
URL: <input type="text" name="url" size="60"><br>
<input type="submit" value="GET QR CODE">
</form>
</body>
</html>
EOS
    $c->res->body($res);
}

sub qrres {
    my $self = shift;
    my ($c) = @_;
    my $dir = $c->path_to('root') . '/' . $c->config->{dir}{qr};
    my $uri_base = $c->uri_for('/') . $c->config->{dir}{qr};
    my $qr1 = create_qrcode( $c->req->params->{url}, $dir, 'png');
    my $qr2 = create_qrcode( $c->req->params->{url}, $dir, 'png', { ModuleSize => 2 });
    my $qr3 = create_qrcode( $c->req->params->{url}, $dir, 'png', { ModuleSize => 3 });
    my $qr4 = create_qrcode( $c->req->params->{url}, $dir, 'png', { ModuleSize => 4 });
    my $res = <<EOS;
<html>
<head>
<title></title>
</head>
<body>
<img src="$uri_base/$qr1">$qr1<br>
<img src="$uri_base/$qr2">$qr2<br>
<img src="$uri_base/$qr3">$qr3<br>
<img src="$uri_base/$qr4">$qr4<br>
</body>
</html>
EOS
    $c->res->body($res);
}

sub preuid {
    my $self = shift;
    my ($c) = @_;
    my $res = <<EOS;
<html>
<head>
<title></title>
</head>
<body>
<form method="get" action="./uid" utn>
    <input type="submit" value="go">
</form>
</body>
</html>
EOS
    $c->res->body($res);
}

sub uid {
    my $self = shift;
    my ($c) = @_;
    my $agent  = HTTP::MobileAgent->new;
    my $userid = HTTP::MobileUserID->new($agent);
    my $uid = $userid->id;
    my $res = <<EOS;
<html>
<head>
<title></title>
</head>
<body>
EOS
    if ($agent->is_ezweb) {
        $res .= 'You are using AU<br>';
    }
    elsif ($agent->is_docomo) {
        $res .= 'You are using DoCoMo<br>';
    }
    elsif ($agent->is_softbank) {
        $res .= 'You are using SoftBank<br>';
    }
    else {
        $res .= 'You are PC user<br>';
    }
    $res .= 'USERAGENT' . $agent->user_agent . '<br>';
    $res .= 'UID:' . $uid . '<br>';
    $res .= <<EOS;
</body>
</html>
EOS
    $c->res->body($res);
}

sub create_qrcode {
    eval "use GD::Barcode::QRcode;";
    $@ and die $@;
    my ($url, $dir, $type, $opts) = @_;
    my $fh = File::Temp->new(
        DIR     => $dir,
        SUFFIX  => ".$type",
        TMPDIR  => 1,
    );
    for (keys %QRCODE_DEFAULT) {
        defined $opts->{$_} or
            $opts->{$_} = $QRCODE_DEFAULT{$_};
    }
    my $bc = GD::Barcode::QRcode->new($url, $opts);
    print $fh $bc->plot->$type;;
    $fh->unlink_on_destroy(0);
    cleanup($dir, 600);
    return basename $fh->filename;
}

sub cleanup {
    my ($dir, $expire) = @_;
    opendir my $d, $dir or die "can't open directory $dir($!)";;
    for my $f (grep !/^\.\.?$/, readdir $d) {
        my $st = stat "$dir/$f";
        if ($st->ctime + $expire < time) {
            unlink "$dir/$f";
        }
    }
    closedir $d;
}

1;
