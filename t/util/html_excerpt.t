#!perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Data::Dumper;
use lib 'lib';
use Q1::jQuery;


BEGIN {
	use_ok('Q1::Utils::HTML::Excerpt') || print "Bail out!";
}


my $html_source = join "\n", <DATA>;
my $html_excerpt = Q1::Utils::HTML::Excerpt->new();


# excerpt
subtest 'excerpt' => sub {

	my $output = $html_excerpt->excerpt($html_source, { max_frases => 3 });

	my $expected_output = join "\n",
		"With any CMS, whether it's Movable Type, WordPress, Joomla, etc., one big problem is automatically creating fully formatted HTML excerpts.",
		"The problem is that it's very difficult to know where exactly to split the HTML code without leaving an orphaned HTML tag somewhere. Many website publishers simply force their writers to manually insert a HTML excerpt into a separate field.";

	is $html_excerpt->excerpt($html_source, { max_frases => 3 }), $expected_output, '3 frases';


	$expected_output = join "\n",
		"With any CMS, whether it's Movable Type, WordPress, Joomla, etc., one big problem is automatically creating fully formatted HTML excerpts.",
		"The problem is that it's very difficult to know where exactly to split the HTML code without leaving an orphaned HTML tag somewhere.";

	is $html_excerpt->excerpt($html_source, { max_frases => 2 }), $expected_output, '2 frases';



	is $html_excerpt->excerpt($html_source, { max_frases => 1 }),
	   "With any CMS, whether it's Movable Type, WordPress, Joomla, etc., one big problem is automatically creating fully formatted HTML excerpts.",
	   '1 frase';
};



# excerpt (pagebreak disabled)
# subtest	'pagebreak disabled' => sub {
#
# 	my $output = $html_excerpt->excerpt($html_source, { use_pagebreak => 0 });
#
# 	my $expected_output = <<END;
# <p class="entry-content entry">With any CMS, whether it's <a href="http://www.movabletype.org">Movable Type</a>, <a href="http://wordpress.org">WordPress</a>, <a href="http://www.joomla.com">Joomla</a>, etc., one big problem is <em>automatically</em> creating fully&nbsp;formatted HTML excerpts. The problem is that it's very difficult to know where exactly to split the HTML code without leaving an orphaned HTML tag somewhere. Many website publishers simply force their writers to <em>manually</em> insert a HTML excerpt into a separate field.</p>
# END
# 	chomp $expected_output;
#
# 	is $output, $expected_output, 'excerpt() (pagebreak disabled)';
#
#
# 	# excerpt (empty or undefined source)
# 	#diag "(empty or undefined source)";
# 	is $html_excerpt->excerpt(''), '', 'empty';
# 	is $html_excerpt->excerpt(), '', 'undefined';
# };


done_testing;


__DATA__
<p class="entry-content entry">

	With any CMS, whether it's <a href="http://www.movabletype.org">Movable Type</a>, <a href="http://wordpress.org">WordPress</a>, <a href="http://www.joomla.com">Joomla</a>, etc., one big problem is <em>automatically</em> creating fully&nbsp;formatted HTML excerpts.<br>The problem is that it's very difficult to know where exactly to split the HTML code without leaving an orphaned HTML tag somewhere. Many website publishers simply force their writers to <em>manually </em>insert a HTML excerpt into a separate field. This isn't an optimal solution, since the writer may have to have some knowledge of HTML, unless of course the excerpt field sports a WYSIWYG editor. Regardless, it's still an extra step to copy/paste an excerpt from the main article into another field. Many blogging and CMS platforms do <strong>automatically</strong> generate an excerpt but they strip out all HTML. <img title="smiley-frown" src="http://blog.tmcnet.com/mt-static/plugins/TinyMCE/lib/jscripts/tiny_mce/plugins/emotions/img/smiley-frown.gif" border="0" alt="smiley-frown"><br><br>Some CMS platforms do a simple word count and cut the article at an arbitrary number word count. The problem with this is it cuts the sentence resulting in sentences such as, "I reviewed the new Apple", or "Today, a new company launched called". Reviewed a new Apple iPhone? Apple iPad? What's the company that launched? Even if you get the full context, I believe it's never a good idea to stop mid-sentence.<br><br>Since we've been using Movable Type since 2004 (before Wordpress became popular), I've developed my own set of <a href="http://blog.tmcnet.com/blog/tom-keating/fastsearch?blogs=4&amp;limit=20&amp;search=Movable+Type+plugins+&amp;submit=Search">Movable Type plugins </a>over the years. One of them I came up with was to address the lack of HTML excerpts in Movable Type.<br><!-- pagebreak --><br>First, let's run down the problems that exist <em>without</em> my plugin:<br>

</p>
