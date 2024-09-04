import subprocess
import readchar
from instructor import OpenAISchema
from pydantic import Field

class Function(OpenAISchema):
    """
    Executes a shell command and returns the output (result).
    """

    shell_command: str = Field(
        ...,
        example="ls -la",
        description="Shell command to execute.",
    )

    class Config:
        title = "execute_shell_command"

    @classmethod
    def execute(cls, shell_command: str) -> str:
        if not hasattr(cls, '_first_execution'):
            cls._first_execution = True
            print("""\033[38;5;208m╭─────────────────── Command Execution Keybindings ───────────────╮
│ \033[37mPress '\033[32my\033[37m' to execute, \033[31mCtrl+C\033[37m to cancel/modify \033[37;2m(once per session)\033[37m\033[38;5;208m│
╰─────────────────────────────────────────────────────────────────╯\033[0m""")

 
        char = readchar.readchar().lower()
        if char != "y":
            return "The Execution aborted by user. DONT TRY AGAIN. Inform the user that the execution was aborted."

        process = subprocess.Popen(
            shell_command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        stdout, stderr = process.communicate()
        exit_code = process.returncode
        if exit_code != 0:
            return f"1. Its important you always inform the user about full outputs 2. if the command is not found, suggest a different command and ask the user if you should run it. --- Exit code: {exit_code} and Error output:\n{stderr.decode()}"
        else:
            return f"Exit code: {exit_code}, Output:\n{stdout.decode()}"
