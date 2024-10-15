#!/usr/bin/perl
use strict;
use Data::Dumper;

my %attributes;

sub expand {
    my ($attribute) = @_;
    if (exists $attributes{$attribute}) {
        return $attributes{$attribute}
    }
    else {
        return "{$attribute}"        
    }
}

my %keep = map { $_ => 1 } (qw/
    docname
    description
    keywords
    release
    maintenance
    prerelease
    major
    minor
    tabs
/);


sub keep {
    my ($attribute) = @_;
    return 1 if $attribute =~ /^page(-|$)/;
    return 1 if $attribute =~ /^version(-|$)/;
    return 1 if $attribute =~ /^vs(-|$)/;
    return 1 if $keep{$attribute};
    return;
}

my $blanks = 0;
while (<>) {
    # expand attributes
    s/\{(\S+?)\}/expand($1)/eg;

    # add new attribute definitions
    if (/^:([a-zA-Z0-9_!-]+):\s*(.*?)\s*$/) {
        my ($k, $v) = ($1, $2);
        if ($k =~ /!/) {
            delete $attributes{$k};
            next;
        }
        elsif (! keep($k)) {
            $attributes{$k} = $v;
            next;
        } 
    }

    # de-mangle the {tabs} and plantuml markers
    s/^\[\{tabs#.*\}\]/[tabs]/;
    s/^\[#.*:::tabs-.*].*$//;
    s/^\[plantum#.*\]/[plantuml]/;

    # de-mangle headings (== to =)
    s/^=(= \S)/$1/;
    s/^=(==+ \S)/$1/;

    # don't print more than 2 blank lines in a row
    if (length == 1) {
        next if $blanks++ >= 2;
    } else {
        $blanks = 0;
    }

    # print lines that we didn't swallow as attribute definitions
    print;
}

