<?
/**
 * Notes (no auth)
 * Webinterface
 */

$file = "/var/www/itfollows/notes.txt";
$file_json = "/var/www/itfollows/notes.json";
$head = "https://<path to>/itfollows/";

/**
 * helper: convert plaintext
 */
/*die(_transcode());
function _transcode() {
        global $file;
        $f = fopen($file, "r") or die("err _read_file()");
        $arr = [];
        while (!feof($f)) {
			$ln = trim(fgets($f));
			if (!strlen($ln)) continue;
			array_push($arr, _getId() . '|||' . $ln);
        }
        fclose($f);
	$f = fopen($file, "w") or die("err fopen");
	fwrite($f, implode("\n", $arr));
	fclose($f);
	return "transcoded";
}*/

/**
 * @return unique id
 */
function _getId() {
	return time().md5(uniqid(rand(), true));
}

/**
 * Reply wrapper
 */
function _die() {
	global $head;
	if (isset($_POST['api'])) {
		header("HTTP/1.1 200 OK");
		die;
	} // else
        header("Location: $head");
        die;
}

/**
 * Sanitize text
 */
function _out_html($txt) {
	$chunks = explode('|||', $txt);
	return array($chunks[0], $chunks[1]);
}
function _out_json($txt) {
	$txt = trim(strip_tags(htmlspecialchars_decode($txt, ENT_QUOTES)));
	return $txt;
}
function _in($txt) {
	$txt = htmlspecialchars(strip_tags($txt));
	return $txt;
}

/**
 * Write $json_file
 */
function write_json() {
	global $file_json;
	$f = fopen($file_json, "w") or die("err write_json()");
	fwrite($f, json_encode(_read_file()));
	fclose($f);
}

/**
 * Read and process $file for json output
 * @return array
 */
function _read_file() {
	global $file;
	$f = fopen($file, "r") or die("err _read_file()");
	$arr = [];
	while (!feof($f)) {
		$chunks = explode('|||', fgets($f));
		if (count($chunks) < 2) continue;
		$id = trim($chunks[0]);
		$note = _out_json($chunks[1]);
		if (!strlen($note)) continue;
		array_push($arr, (object) ['id' => $id, 'note' => $note]);
	}
	fclose($f);
	return array_reverse($arr);
}

// end FUNC

if (isset($_POST['save']) && !empty($_POST['text'])) {
	$f = fopen($file, "a") or die("err fopen");
	$t = _in($_POST['text']);

	$chunks = preg_split('/\s+/', $t);
	$chunksp = array();
	foreach ($chunks as $chunk) {
		if (filter_var($chunk, FILTER_VALIDATE_URL)) {
			array_push($chunksp, '<a href="'.$chunk.'">'.$chunk.'</a>');
			continue;
		}
		array_push($chunksp, $chunk);
	}
	$t = implode(' ', $chunksp);

	fwrite($f, "\n" . _getId() . '|||' . $t);
	fclose($f);
	write_json();
	_die();
}
else if (isset($_POST['update'])) {
	write_json();
	_die();
}
else if (isset($_POST['destroy'])) {
	fclose(fopen($file, 'w'));
	write_json();
	_die();
}
else if (isset($_REQUEST['delete']) && strlen($_REQUEST['delete']) == 42) {
	$_arr = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
	$arr = [];
	foreach ($_arr as $ln) {
		$chunks = explode('|||', $ln);
		if ($chunks[0] === $_REQUEST['delete']) continue;
		array_push($arr, $ln);
	}
	$f = fopen($file, "w") or die("err delete");
	fwrite($f, implode("\n", $arr));
	fclose($f);
	write_json();
	_die();
}

$f = array_reverse(file($file));
?>
<!DOCTYPE HTML>
<html lang="en">
<head>
<meta charset=utf-8>
<meta name='viewport' content='width=device-width' />
<title>It follows</title>
<link href="resource.css" rel="stylesheet" type="text/css" />
<script src="resource.js"></script>
</head>
<body>
<div id="container-ctrl">
	<div id="save" class="ctrl-top">
		<form method="post">
			<input type="hidden" name="save" value="1" />
			<input type="text" name="text" />
			<input type="submit" value="save" />
		</form>
	</div>
	<div id="update" class="ctrl-top">
		<form method="post">
			<input type="hidden" name="update" value="1" />
			<input type="submit" value="update" title="update json" />
		</form>
	</div>
</div> <!-- /container-ctrl -->
<div id="content">
<hr />
<?
$i=0;
foreach ($f as $ln) {
	if (++$i > 100) break;
	list($id, $note) = _out_html($ln);
?>
<div class="ln">
	<span><?=$note;?></span>
	<span class="delete"><a href="javascript:;" onclick="_confirm('<?=$id;?>');">[del]</a></span>
</div>
<?
}
?>
</div> <!-- /content -->
<hr />
<form method="post">
	<input type="hidden" name="destroy" value="1" />
	<input type="submit" value="destroy" title="purge notes" />
</form>
<br />
<br />
</body>
</html>
