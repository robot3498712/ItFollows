/**
 * notes - functions
 */

function _confirm(id) {
	if (!confirm('Delete note?')) return;
	window.location.href = `?delete=${id}`;
}
