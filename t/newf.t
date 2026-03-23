use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempdir);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
use Test::More;

my $repo = abs_path(catdir($FindBin::Bin, '..'));
my $newf = catfile($repo, 'src', 'newf');
my $templ_root = catdir($repo, 't', 'templ');
my $config_root = catdir($repo, 't', 'config');
my $bin_root = catdir($repo, 't', 'bin');

sub write_text {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>', $path or die "open $path failed: $!";
    print {$fh} $content;
    close $fh or die "close $path failed: $!";
}

sub write_bin {
    my ($path, $content) = @_;
    make_path(dirname($path));
    open my $fh, '>', $path or die "open $path failed: $!";
    binmode $fh;
    print {$fh} $content;
    close $fh or die "close $path failed: $!";
}

sub slurp_text {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path failed: $!";
    local $/;
    my $data = <$fh>;
    close $fh or die "close $path failed: $!";
    return $data;
}

sub slurp_bin {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path failed: $!";
    binmode $fh;
    local $/;
    my $data = <$fh>;
    close $fh or die "close $path failed: $!";
    return $data;
}

sub normalize_output {
    my ($text) = @_;
    $text =~ s/\A(?:\n)+//;
    return $text;
}

my $home = tempdir(CLEANUP => 1);

sub run_newf {
    my (@args) = @_;
    local $ENV{PATH} = $bin_root . ':' . ($ENV{PATH} // '');
    local $ENV{XDG_CONFIG_HOME} = $config_root;
    local $ENV{HOME} = $home;

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $newf, @args);
    close $in;
    my $stdout = do { local $/; <$out> // '' };
    my $stderr = do { local $/; <$err> // '' };
    waitpid($pid, 0);
    my $exit = $? >> 8;
    return ($exit, $stdout, $stderr);
}

remove_tree($templ_root) if -d $templ_root;
make_path($templ_root);

write_text(catfile($templ_root, 'nftxt'), "text: NAME\n");
write_text(catfile($templ_root, 'nffoo', 'default'),
    "name: NAME\narg1: ARG1\narg2: ARG2\nargc: ARGC\n");
write_text(catfile($templ_root, 'nftsh', 'tex'), "kind: sh-tex\n");
write_text(catfile($templ_root, 'nfcase'), "case: NAME\n");
write_text(catfile($templ_root, 'nfcfg'), "x: X\nauthor: AUTHOR\n");
write_text(catfile($templ_root, 'nfprio'), "prio: base\n");
write_bin(catfile($templ_root, 'nfbin'), "A\0B\1C");
write_text(catfile($templ_root, 'nfexe'),
    "#!/bin/sh\n" . q{printf 'from-exec\n' > "$1"} . "\n");
chmod 0755, catfile($templ_root, 'nfexe') or die "chmod nfexe failed: $!";

my $default_cfg_dir = catdir($config_root, 'newf');
my $default_cfg = catfile($default_cfg_dir, 'config.m4');
if (!-e $default_cfg) {
    make_path($default_cfg_dir);
    write_text($default_cfg, slurp_text(catfile($config_root, 'config.m4')));
}

my $work = tempdir(CLEANUP => 1);

subtest 'no target' => sub {
    my ($exit, $stdout, $stderr) = run_newf();
    isnt($exit, 0, 'exit non-zero');
    is($stdout, '', 'stdout empty');
    like($stderr, qr/No target specified!/, 'stderr mentions missing target');
};

subtest 'm4 args and fallback template' => sub {
    my $target = catfile($work, 'file.nffoo');
    my ($exit) = run_newf('-t', 'nffoo/bar/baz', $target);
    is($exit, 0, 'exit 0');
    is(normalize_output(slurp_text($target)),
        "name: $target\narg1: bar\narg2: baz\nargc: 2\n",
        'm4 variables expanded');
};

subtest 'auto detect with ./ prefix' => sub {
    my $target = catfile($work, 'script.nftsh');
    my ($exit) = run_newf('-t', './tex', $target);
    is($exit, 0, 'exit 0');
    is(normalize_output(slurp_text($target)), "kind: sh-tex\n",
        './ replaced with detected type');
};

subtest '-T reset' => sub {
    my $target = catfile($work, 'reset.nftxt');
    my ($exit) = run_newf('-t', 'nffoo', '-T', $target);
    is($exit, 0, 'exit 0');
    is(normalize_output(slurp_text($target)), "text: $target\n",
        'type reset to auto');
};

subtest 'case-insensitive match' => sub {
    my $case_target = catfile($work, 'NfCase');
    my ($exit2) = run_newf($case_target);
    is($exit2, 0, 'exit 0');
    is(normalize_output(slurp_text($case_target)), "case: $case_target\n",
        'case-insensitive template match');
};

subtest 'illegal -t acts like -T' => sub {
    my $target = catfile($work, 'bad.nftxt');
    my ($exit, undef, $stderr) = run_newf('-t', '', $target);
    is($exit, 0, 'exit 0');
    like($stderr, qr/Illegal type path/, 'warned about illegal type');
    is(normalize_output(slurp_text($target)), "text: $target\n",
        'auto type used');
};

subtest 'config order with -c' => sub {
    my $a = catfile($work, 'a.m4');
    my $b = catfile($work, 'b.m4');
    write_text($a, "define(`X', `A')\n");
    write_text($b, "define(`X', `B')\n");
    my $target = catfile($work, 'cfg.nfcfg');
    my ($exit) = run_newf('-c', $a, '-c', $b, '-t', 'nfcfg', $target);
    is($exit, 0, 'exit 0');
    is(normalize_output(slurp_text($target)), "x: B\nauthor: yuandi42\n",
        'last -c overrides earlier, default config applied');
};

subtest '-d priority' => sub {
    my $d1 = tempdir(CLEANUP => 1);
    my $d2 = tempdir(CLEANUP => 1);
    write_text(catfile($d1, 'nfprio'), "prio: d1\n");
    write_text(catfile($d2, 'nfprio'), "prio: d2\n");
    my $target = catfile($work, 'prio.nfprio');
    my ($exit) = run_newf('-d', $d1, '-d', $d2, '-t', 'nfprio', $target);
    is($exit, 0, 'exit 0');
    is(normalize_output(slurp_text($target)), "prio: d2\n", 'last -d wins');
};

subtest '-o stdout separation' => sub {
    my $t1 = catfile($work, 'out1.nftxt');
    my $t2 = catfile($work, 'out2.nftxt');
    my ($exit, $stdout, $stderr) = run_newf('-o', $t1, $t2);
    is($exit, 0, 'exit 0');
    is($stderr, '', 'stderr empty');
    my @parts = split /\0/, $stdout, -1;
    is(scalar @parts, 2, 'stdout has NULL separator');
    is(normalize_output($parts[0]), "text: $t1\n", 'first stdout part');
    is(normalize_output($parts[1]), "text: $t2\n", 'second stdout part');
    ok(!-e $t1, 't1 not created on disk');
    ok(!-e $t2, 't2 not created on disk');
};

subtest 'binary template copy' => sub {
    my $target = catfile($work, 'bin.nfbin');
    my ($exit) = run_newf('-t', 'nfbin', $target);
    is($exit, 0, 'exit 0');
    is(slurp_bin($target), "A\0B\1C", 'binary copied');
};

subtest 'executable template with -o' => sub {
    my $target = catfile($work, 'exec.nfexe');
    my ($exit) = run_newf('-o', '-t', 'nfexe', $target);
    is($exit, 0, 'exit 0');
    is(slurp_text($target), "from-exec\n", 'exec template created file');
};

subtest '-f overwrite and mkdir' => sub {
    my $target = catfile($work, 'over.nftxt');
    write_text($target, "old\n");
    my ($exit1, undef, $stderr1) = run_newf('-t', 'nftxt', $target);
    is($exit1, 0, 'exit 0');
    like($stderr1, qr/already exists/, 'warned about overwrite');
    is(slurp_text($target), "old\n", 'content unchanged without -f');

    my ($exit2) = run_newf('-f', '-t', 'nftxt', $target);
    is($exit2, 0, 'exit 0');
    is(normalize_output(slurp_text($target)), "text: $target\n",
        'overwritten with -f');

    my $nested = catfile($work, 'dir1', 'dir2', 'new.nftxt');
    my ($exit3, undef, $stderr3) = run_newf('-t', 'nftxt', $nested);
    is($exit3, 0, 'exit 0');
    like($stderr3, qr/Failed to open .*No such file or directory/,
        'warned about missing parent');
    ok(!-e $nested, 'nested file not created without -f');

    my ($exit4) = run_newf('-f', '-t', 'nftxt', $nested);
    is($exit4, 0, 'exit 0');
    is(normalize_output(slurp_text($nested)), "text: $nested\n",
        'created with -f');
};

subtest 'xbit flags' => sub {
    my $a = catfile($work, 'a.nftxt');
    my $b = catfile($work, 'b.nftxt');
    my $c = catfile($work, 'c.nftxt');
    my ($exit) = run_newf('+x', $a, '-X', $b, '-x', $c);
    is($exit, 0, 'exit 0');
    ok(-x $a, 'a is executable');
    ok(!-x $b, 'b is not executable');
    ok(-x $c, 'c is executable via toggle');
};

subtest '-v logs to stderr' => sub {
    my $target = catfile($work, 'verb.nftxt');
    my ($exit, $stdout, $stderr) = run_newf('-v', '-t', 'nftxt', $target);
    is($exit, 0, 'exit 0');
    is($stdout, '', 'stdout empty');
    like($stderr, qr/\bCreate\b.*\busing\b/, 'verbose message on stderr');
};

done_testing();
