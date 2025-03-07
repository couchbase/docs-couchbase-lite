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

    # we don't need these ones created by assembler
    return if $attribute eq 'page-module';
    return if $attribute eq 'page-relative-src-path';
    return if $attribute =~/^page-origin/;

    return 1 if $attribute =~ /^page-/;
    # return 1 if $attribute =~ /^version(-|$)/;
    # return 1 if $attribute =~ /^vs(-|$)/;
    return 1 if $keep{$attribute};
    return;
}

my $blanks = 0;
my $strip_headings;

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


    # de-mangle headings
    if (/^(=+) \S/) {
        s/^===== {empty}/====== {empty}/ or do {
            $strip_headings //= (length $1) - 1;
            s/^={$strip_headings}(=* \S)/$1/;
        }
    }

    # remove spurious passthrough mangling
    s/^pass:q,a\[(.*)\]/$1/;

    # [discrete# mangling
    s/^\[discrete.column/[.column/;
    s/^\[discrete#/[#/;
    s/^\[discret#(.*)e\]/[discrete#$1/;

    # get rid of '// Define our environment' comments in calling pages
    s/^\/\/ Define.*//;

    # don't print more than 2 blank lines in a row
    if (length == 1) {
        next if $blanks++ >= 2;
    } else {
        $blanks = 0;
    }

    # print lines that we didn't swallow as attribute definitions
    print;
}

