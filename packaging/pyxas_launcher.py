import multiprocessing
import os
import sys
import traceback


def _log_path():
    log_dir = os.path.join(os.path.expanduser('~'), '.pyxas')
    os.makedirs(log_dir, exist_ok=True)
    return os.path.join(log_dir, 'pyxas.log')


def _show_crash_dialog(log_file, err_text):
    try:
        from PyQt5.QtWidgets import QApplication, QMessageBox
        app = QApplication.instance() or QApplication(sys.argv)
        QMessageBox.critical(None, 'PyXAS crashed',
                             f'{err_text}\n\nFull log: {log_file}')
    except Exception:
        pass


def run():
    multiprocessing.freeze_support()
    log_file = _log_path()
    # A windowed build has no console (sys.stdout/stderr are None), which breaks tqdm and print-based progress.
    log = open(log_file, 'w', buffering=1, encoding='utf-8', errors='replace')
    sys.stdout = log
    sys.stderr = log
    try:
        from pyxas.pyxas_gui import main
        main()
    except SystemExit:
        raise
    except BaseException:
        err = traceback.format_exc()
        log.write(err)
        log.flush()
        _show_crash_dialog(log_file, err.strip().splitlines()[-1])
        sys.exit(1)


if __name__ == '__main__':
    run()
