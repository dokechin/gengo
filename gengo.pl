use strict;
use warnings;
use DateTime::Calendar::Japanese::Era;
use Encode qw/encode_utf8/;
use Furl;
use utf8;
use JSON::XS qw/decode_json/;
use Algorithm::Permute;

my @eras = DateTime::Calendar::Japanese::Era->registered();

my @letters;
my %era_hash;
for my $era (@eras) {
    push @letters, split (//, $era->name);
    $era_hash{$era->name} = 1;
}

#重複を削除
my %ucs;
for my $letter(@letters){
   $ucs{$letter} = ord($letter);
}

#画数を求める
my @mojis;
my $ua = Furl->new;
for my $letter(keys %ucs){
    my $url = sprintf 'https://mojikiban.ipa.go.jp/mji/q?UCS=0x%X', $ucs{$letter};
    my $res = $ua->get($url);
    my $data = decode_json $res->content;
    push @mojis, {letter => $letter, kaku => $data->{"results"}[0]->{"総画数"}}; 
}

#２文字取り出す
my $p = Algorithm::Permute->new([0 .. scalar(@mojis)-1], 2);
 
while (my @res = $p->next) {
    my $total = 0;
    my $g = "";
    for my $i (@res){
        $total += $mojis[$i]->{"kaku"};
        $g .= $mojis[$i]->{"letter"};
    }
    if ($total < 20 && !exists($era_hash{$g})){
        print encode_utf8($g), $total,"\n";
    }
}
