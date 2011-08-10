module Pod::To::HTML;
use Text::Escape;

my $prelude = q[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
           "http://www.w3.org/TR/html4/loose.dtd"> 
<html><head><title>Pod document</title> 
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" > 
<link rel="stylesheet" type="text/css" title="pod_stylesheet"
      href="http://perlcabal.org/syn/perl.css">
</head>
<body class="pod">
<a name='___top' class='dummyTopAnchor' ></a>
];

my @indexes;
my @body;

sub pod2html($pod) is export {

    @body.push: whatever2html($pod);
    return $prelude ~ buildindexes() ~ @body.join ~ "</body></html>";
}

sub whatever2html($node) {
    given $node {
        when Pod::Heading      { heading2html($node)             }
        when Pod::Block::Code  { code2html($node)                }
        when Pod::Block::Named { named2html($node)               }
        when Pod::Block::Para  { para2html($node)                }
        when Pod::Block::Table { table2html($node)               }
#        when Pod::Block::Declarator { declarator2html($node)     }
        when Pod::Item         { item2html($node)                }
        when Positional        { $node.map({whatever2html($_)}).join }
        when Pod::Block::Comment { }
        default                { $node.Str                       }
    }
}

sub buildindexes {
    my $r = "<div class='indexgroup'>\n";
    my @opened;
    for @indexes -> $p {
        my $lvl  = $p.key;
        my $head = $p.value;
        if +@opened {
            while @opened[*-1] > $lvl {
                $r   ~= "</ul>\n";
                @opened.pop;
            }
        }
        my $last = @opened[*-1] // 0;
        if $last < $lvl {
            $r ~= "<ul class='indexList indexList$lvl'>\n";
            @opened.push($lvl);
        }
        $r ~= "<li class='indexItem indexItem$lvl'><a href='#$head'>{$head}</a>\n";
    }
    for @opened {
        $r ~= "</ul>\n";
    }
    $r ~= "</div>\n";

    return $r;
}

sub heading2html($pod) {
    my $lvl = $pod.level;
    my $txt = escape($pod.content[0].content.Str, 'html');
    @indexes.push: Pair.new(key => $lvl, value => $txt);
    return "<h$lvl><a class='u' href='#___top' title='click to go to top of document' name='$txt'>{$txt}</a></h$lvl>\n";
}

sub named2html($pod) {
    given $pod.name {
        when 'pod'  { whatever2html($pod.content)     }
        when 'para' { para2html($pod.content[0])      }
        when 'defn' { whatever2html($pod.content[0]) ~ "\n"
                    ~ whatever2html($pod.content[1..*-1]) }
        when 'config' { }
        when 'nested' { }
        default     { $pod.name ~ "<br />\n" ~ whatever2html($pod.content) }
    }
}

sub para2html($pod) {
    '<p>' ~ escape($pod.content.join("\n"), 'html') ~ "</p>\n"
}

sub code2html($pod) {
    '<pre>' ~ escape($pod.content, 'html') ~ "</pre>\n"
}

sub item2html($pod) {
#FIXME
    '<ul><li>' ~ whatever2html($pod.content) ~ "</li></ul>\n"
}

sub table2html($pod) {
    my $r = "<table border='1'>\n";
    if $pod.caption {
        $r ~= "<tr>{escape($pod.caption, 'html')}</tr>\n";
    }
    if $pod.headers {
        $r ~= "<tr>\n";
        for $pod.headers {
            $r ~= "<th>{escape($_, 'html')}</th>\n";
        }
        $r ~= "</tr>\n";
    }
    for $pod.content -> $line {
        $r ~= "<tr>\n";
        for $line.list {
            $r ~= "<td>{escape($_, 'html')}</td>\n";
        }
        $r ~= "</tr>\n";
    }
    $r ~= "</table>\n";
    return $r;
}
