"""Compatibility launcher; migrations require administrator authentication."""
import sys
from admin import main
if __name__ == '__main__':
    sys.argv = [sys.argv[0], 'migrate']
    raise SystemExit(main())
