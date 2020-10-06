class DirectoryDoesNotExist(Exception):
    """Raised if the specified directory does not exist."""

    def __init__(self, directory):
        self.directory = directory

    def __str__(self):
        return "'{}' is not a directory".format(self.directory)


class LogitLinAlgError(Exception):
    """Raised if the LinAlgError"""

    def __init__(self, feature_name):
        self.feature_name = feature_name

    def __str__(self):
        if 'Singular matrix' in str(Exception):
            print("{} has {}".format(self.feature, Exception))
            return "{} has {}".format(self.feature, Exception)
        else:
            return "{} has LinAlgError error".format(self.feature)


class LogitConvertingWarning(Warning):
    def __init__(self, feature_name):
        self.feature_name = feature_name

    def __str__(self):
        return "{} has warning {}".format(self.feature, Warning)



