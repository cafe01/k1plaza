
use Test::K1Plaza;
use FindBin;
use Mojo::Util qw/ md5_sum /;
use Mojo::File qw/ path /;

my $app = app();

my $api = $app->api('Mail');


subtest 'new_mail() simple' => sub {

    my $mail = $api->new_mail({
    	from    => '"Q1 Mailer test script!" <testscript@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => 'Just tésting...',
    	body    => 'Hello world! ééé!!!',
    });

    is $mail->head->get('From'), '"Q1 Mailer test script!" <testscript@q1software.com>'."\n", 'from';
    is $mail->head->get('To'), 'cafe01@gmail.com'."\n", 'to';
    is $mail->head->get('Subject'), "Just tésting...\n", 'subject';
    is scalar($mail->parts), 1, 'parts';
    is $mail->parts(0)->body->[0], "Hello world! ééé!!!\n", 'body';

};

subtest 'new_mail() template' => sub {

    my $mail = $api->new_mail({
    	from    => '"Q1 Mailer test script!" <testscript@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => 'Just tésting...',
        template => "email.tpl.txt",
    });

    is $mail->parts(0)->body->[0], "Email enviado via txt template!\n", 'template body';
};

subtest 'new_mail() html' => sub {

    my $mail = $api->new_mail({
        from    => '"Q1 Mailer test script!" <testscript@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => 'Just tésting...',
        html_template => "email.tpl.html",
    });

    is $mail->parts(0)->body->[0], "<h1>Email enviado via html template!</h1>\n", 'template body';
};

subtest 'new_mail() text+html' => sub {


    my $mail = $api->new_mail({
        from    => '"Q1 Mailer test script!" <testscript@q1software.com>',
        to      => 'cafe01@gmail.com',
        subject => 'Just tésting...',
        template => "email.tpl.txt",
        html_template => "email.tpl.html",
    });

    is scalar($mail->parts), 2, '2 parts';
    is $mail->parts(0)->body->[0], "Email enviado via txt template!\n", 'txt body';
    is $mail->parts(1)->body->[0], "<h1>Email enviado via html template!</h1>\n", 'html body';
};


subtest 'send_mail - missing username/password' => sub {

    ok dies { $api->send_mail({
    	from    => '"Q1 Mailer test script!" <testscript@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => 'Just tésting...',
        template => "email.tpl.txt",
    }) };
};


subtest 'send_mail - (mailtrap)' => sub {

    skip_all 'set MAILTRAP_USER/MAILTRAP_PASS'
        unless $ENV{MAILTRAP_USER} && $ENV{MAILTRAP_PASS};

    app->config->{smtp} = {
        host => 'smtp.mailtrap.io',
        port => 2525,
        username => $ENV{MAILTRAP_USER},
        password => $ENV{MAILTRAP_PASS},
    };

    ok $api->send_mail({
    	from    => '"K1Plaza Mail API" <testscript@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => "Mail API test - ".localtime(),
        body => "all good",
    });
};


subtest 'send_mail - (amazon)' => sub {

    skip_all 'set SES_USER/SES_PASS'
        unless $ENV{SES_USER} && $ENV{SES_PASS};

    app->config->{smtp} = {
        host => 'email-smtp.us-east-1.amazonaws.com',
        port => 465,
        ssl => 1,
        username => $ENV{SES_USER},
        password => $ENV{SES_PASS},
    };

    ok $api->send_mail({
    	from    => '"K1Plaza Mail API" <naoresponder@q1software.com>',
    	to      => 'cafe01@gmail.com',
    	subject => "Mail API test - ".localtime(),
        body => "all good",
    });
};


done_testing();
