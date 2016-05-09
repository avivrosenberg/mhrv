function [ res, out ] = jsystem( cmd, shell, dir )
%JSYSTEM Execute a shell command
%   Executes a shell command as a subprocess using java's ProcessBuilder
%   class. This is much faster than using the builtin matlab 'system'
%   command.
%
%   Input arguments:
%   cmd -   A string, command to execute (with args and any shell
%           directives), e.g. 'ls -al /foo | grep bar > baz.txt'
%   shell - Optional. If specified, can be either a path of the shell to
%          invoke (e.g. '/bin/zsh') or the string 'noshell' in which case the
%          command will be run directly. In case this argument is omitted,
%          defatuls to '/bin/sh'.
%   dir -  Optional. Working directory for the process running the command.
%          If omitted defaults to the current matlab working
%          directory.
%
%   Output arguments:
%   res - The result code returned by the process.
%   out - The output of the process (both stdout and stderr).
%
%   Global settings:
%   jsystem_path - Set this global variable to a cell array of paths that
%   will be prefixed to the PATH enviroment variable of the process running
%   the command. Example: global jsystem_path; jsystem_path = {'/foo', '/bar/baz'};

global jsystem_path;
if (nargin == 0)
    error('No command specified');
end
if (~exist('shell', 'var'))
    shell = '/bin/sh';
end
if (~exist('dir', 'var'))
    dir = pwd;
end

% Create a java ProcessBuilder instance
pb = java.lang.ProcessBuilder({''});

% Set it's working directory to the current matlab dir
pb.directory(java.io.File(dir));

% Configure stderror redirection to stdout (so we can read both of them
% from a single stream)
pb.redirectErrorStream(true);

% If the user doesn't wan't to use a shell, split the command from it's
% arguments. Otherwise, prefix the shell invocation.
if (strcmpi(shell, 'noshell'))
    shellcmd = strsplit(cmd);
else
    shellcmd = {shell, '-c', cmd};

    % Setup path for process (only relevant if using a shell)
    if (~isempty(jsystem_path) && iscellstr(jsystem_path))
        path = [strjoin(jsystem_path, ':') ':' char(pb.environment.get('PATH'))];
        pb.environment.put('PATH', path);
    end
end

% Set the command to run
pb.command(shellcmd);

% Start running the new process (non blocking)
process = pb.start();

% Read output from the process
is = process.getInputStream();
scanner = java.util.Scanner(is).useDelimiter('\\A'); % '\A' is the start of input token
if scanner.hasNext() % blocks until start of stream
    out = scanner.next(); % blocks until end of stream
else
    out = '';
end

% Get the result code from the process
res = process.waitFor();

end