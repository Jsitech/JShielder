#!/usr/bin/perl

die "Usage: $0 <module name> <SHA size> <filename>" if ($#ARGV != 2);

my $sha = '';

my $mod = $ARGV[0];
my $size = $ARGV[1];
my $file = $ARGV[2];

eval "use $mod";

die "Invalid module: $mod" if ($@);

if ($mod eq 'Digest::SHA1' || $mod eq 'Digest::Whirlpool' || $mod eq 'Crypt::RIPEMD160' || $mod eq 'Digest::MD5') {
	$sha = $mod -> new;
}
elsif ($mod eq 'Digest::SHA256') {
	$sha = Digest::SHA256::new($size);
}
else {
	$sha = $mod -> new($size);
}

# Open file in binary mode
open(FILE, $file) or die "Can't open file '$file'";
binmode(FILE);

# Hash file contents
$sha -> add($_) while (<FILE>);

close(FILE);

$_ = $sha -> hexdigest;
s/ //g;
print $_, "\n";

exit;
