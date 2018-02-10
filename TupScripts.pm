# Perl functions used by the tup-related scripts in this same directory
package TupScripts;
use strict;
use warnings;

our($arg0) = $0 =~ m(([^/]+)$);


# Pretty-prints the POD at the top of the main perl script
sub help {
  local $_ = `(pod2man $0 |nroff -man) 2>/dev/null` ||
             `pod2text $0 2>/dev/null` ||
             `sed -ne '/^=pod/,/^=cut/p' $0 2>/dev/null`;
  die "$0: see source file for documentation\n" unless $_;
  if (open LESS, "|less -R") {
    print LESS $_;
    close LESS;
  } else {
    print $_;
  }
};

# Given a name in the file system, return the last component. I.e., the non-directory part.
sub base_name {
    my @components = split /\/+/, $_[0];
    pop @components while @components && !$components[-1];
    die "$arg0: invalid name \"$_[0]\"\n" unless @components;
    return $components[-1];
}

# Given a name in the file system, return just the part after the last
# slash and before the last dot.
sub base_name_no_ext {
    my $final = base_name($_[0]);
    $final = $1 if $final =~ /(.*)\./;
    return $final;
}

# Escape a string for the shell
sub shell_escape {
    local($_) = @_;

    # No escapes necessary if non-empty and contains no shell meta characters
    return $_ if /^[-._+=\w\/]+$/;

    # For readability, |var=v1 v2| becomes |var='v1 v2'| rather than |'var=v1 v2'|
    # Similarly for switches: |--switch=v1 v2| becomes |--switch='v1 v2'|
    return $1 . shell_escape($2) if /^(-*\w+=)(.*)/;

    s/'/'"'"'/g;
    return "'$_'";
}

# Return the language for a file based only on the file name (because the file might not exist or might be empty or
# might have incorrect contents). The by-name restriction is because this needs to be called to create Tup rules, which
# happens before files are created.
sub language {
    my($file) = @_;

    return "c"       	if $file =~ /\.c$/;
    return "c++"     	if $file =~ /\.(C|cc|cxx|cpp)$/;
    return "d"       	if $file =~ /\.d$/;
    return "header"  	if $file =~ /\.(h|hh|H|hpp|hxx)$/;
    return "library" 	if $file =~ /\.(so|a|dll)$/;
    return "shell"   	if $file =~ /\.sh$/;
    return "object"  	if $file =~ /\.o$/;
    return "executable" if $file =~ /\.exe$/;
    return $1           if $file =~ /\.([^\/]+)$/;
    return "";
}

# True if file is a source language like C or C++
sub is_source_code {
    my($file) = @_;
    my($lang) = language($file);
    return ($lang eq "c" || $lang eq "c++" || $lang eq "d" || $lang eq "header");
}

# True if file is a library, static or shared
sub is_library {
    return language($_[0]) eq "library";
}

# True if file is an object file
sub is_object {
    return language($_[0]) eq "object";
}
    
# Organize source file names by language. Return value is a hash
# indexed by the language and whose value is an array reference for
# the corresponding source file names.
#
# C/C++ source files are indicated by "c" or "c++", but header files
# are grouped under "header".
#
# Unrecognized file names are grouped by their extension(s). Files
# with no extension are grouped under the empty string.
#
# Remember, this is only based on file extensions. It cannot be based
# on file content since it's called with file names that might not
# actually exist yet (such as when building Tup rules).
sub by_language {
    my %ret;
    for my $file (@_) {
	my $lang = language($file);
	$ret{$lang} ||= [];
	push @{$ret{$lang}}, $file;
    }
    return %ret;
}

1;
