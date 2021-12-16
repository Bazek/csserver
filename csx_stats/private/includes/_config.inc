<?php
// Database Settings.
define("DB_HOST", "mysql"); // Database host address. (localhost)
define("DB_USER", "root"); // Database user.
define("DB_PASS", "TralalaTrololo"); // Database password.
define("DB_NAME", $_GET['database'] or $_GET['history'] or "csserver"); // Database Name.

// Steam Api Key.
define("STEAM_API_KEY", "__STEAM_API_KEY__");

// Twig Directories.
define("TWIG_TEMPLATE_DIR", "templates");
define("TWIG_COMPILED_DIR", "templates/compiled");

