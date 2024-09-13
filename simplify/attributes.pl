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
/);


sub keep {
    my ($attribute) = @_;
    return 1 if $attribute =~ /^page-/;
    return 1 if $keep{$attribute};
    return;
}

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

    # print lines that we didn't swallow as attribute definitions
    print;
}

