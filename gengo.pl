use strict;
use warnings;
use DateTime::Calendar::Japanese::Era;
use Encode qw/encode_utf8/;
use Furl;
use utf8;
use JSON::XS qw/decode_json/;
use Algorithm::Permute;
use Text::MeCab;

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
    push @mojis, {letter => $letter, kaku => $data->{"results"}[0]->{"総画数"}, yomi => $data->{"results"}[0]->{"読み"}->{"音読み"}[0]}; 
}

#２文字取り出す
my $p = Algorithm::Permute->new([0 .. scalar(@mojis)-1], 2);
 
my $m = Text::MeCab->new();

while (my @res = $p->next) {
    my $total = 0;
    my $g = "";
    my $yomi = "";
    for my $i (@res){
        $total += $mojis[$i]->{"kaku"};
        $g .= $mojis[$i]->{"letter"};
        $yomi .= $mojis[$i]->{"yomi"};
    }
    my $n = $m->parse($yomi);
    my $feature1 = Encode::decode('utf-8', $n->feature);
    my @feature1 = split ',' , $feature1;

    $n = $n->next;
    my $feature2 = Encode::decode('utf-8', $n->feature);
    my @feature2 = split ',' , $feature2;

    my $general = ($feature1[1] eq "一般" && $feature2[0] eq "BOS/EOS")? 1:0;

    if ($total < 20 && !exists($era_hash{$g}) && $yomi !~ /^[ハマミムメモタチツテトサシスセソハヒフヘホ]/ && !$general){
        printf "%s,%s,%d\n", encode_utf8($g), encode_utf8($yomi), $total;
    }
}
