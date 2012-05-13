/* ATTENTION: You don't need to run or use this file!  The upgrade.php script does everything for you! */

/******************************************************************************/
--- Adding new settings...
/******************************************************************************/

---# Creating login history sequence.
CREATE SEQUENCE {$db_prefix}member_logins_seq;
---#

---# Creating login history table.
CREATE TABLE {$db_prefix}member_logins (
	id_login int NOT NULL default nextval('{$db_prefix}member_logins_seq'),
	id_member mediumint NOT NULL,
	time int NOT NULL,
	ip varchar(255) NOT NULL default '',
	ip2 varchar(255) NOT NULL default '',
	PRIMARY KEY (id_login)
);
---#

---# Copying the current package backup setting...
---{
if (!isset($modSettings['package_make_full_backups']) && isset($modSettings['package_make_backups']))
	upgrade_query("
		INSERT INTO {$db_prefix}settings
			(variable, value)
		VALUES
			('package_make_full_backups', '" . $modSettings['package_make_backups'] . "')");
---}
---#

/******************************************************************************/
--- Updating legacy attachments...
/******************************************************************************/

---# Converting legacy attachments.
---{
$request = upgrade_query("
	SELECT MAX(id_attach)
	FROM {$db_prefix}attachments");
list ($step_progress['total']) = $smcFunc['db_fetch_row']($request);
$smcFunc['db_free_result']($request);

$_GET['a'] = isset($_GET['a']) ? (int) $_GET['a'] : 0;
$step_progress['name'] = 'Converting legacy attachments';
$step_progress['current'] = $_GET['a'];

// We may be using multiple attachment directories.
if (!empty($modSettings['currentAttachmentUploadDir']) && !is_array($modSettings['attachmentUploadDir']))
	$modSettings['attachmentUploadDir'] = unserialize($modSettings['attachmentUploadDir']);

$is_done = false;
while (!$is_done)
{
	nextSubStep($substep);

	$request = upgrade_query("
		SELECT id_attach, id_folder, filename, file_hash
		FROM {$db_prefix}attachments
		WHERE file_hash = ''
		LIMIT $_GET[a], 100");

	// Finished?
	if ($smcFunc['db_num_rows']($request) == 0)
		$is_done = true;

	while ($row = $smcFunc['db_fetch_assoc']($request))
	{
		// The current folder.
		$current_folder = !empty($modSettings['currentAttachmentUploadDir']) ? $modSettings['attachmentUploadDir'][$row['id_folder']] : $modSettings['attachmentUploadDir'];

		// The old location of the file.
		$old_location = getLegacyAttachmentFilename($row['filename'], $row['id_attach'], $row['id_folder']);

		// The new file name.
		$file_hash = getAttachmentFilename($row['filename'], $row['id_attach'], $row['id_folder'], true);

		// And we try to move it.
		rename($old_location, $current_folder . '/' . $row['id_attach'] . '_' . $file_hash);

		// Only update thif if it was successful.
		if (file_exists($current_folder . '/' . $row['id_attach'] . '_' . $file_hash) && !file_exists($old_location))
			upgrade_query("
				UPDATE {$db_prefix}attachments
				SET file_hash = '$file_hash'
				WHERE id_attach = $row[id_attach]");
	}
	$smcFunc['db_free_result']($request);

	$_GET['a'] += 100;
	$step_progress['current'] = $_GET['a'];
}

unset($_GET['a']);
---}
---#

/******************************************************************************/
--- Adding support for IPv6...
/******************************************************************************/

---# Adding new columns to ban items...
ALTER TABLE {$db_prefix}ban_items
ADD COLUMN ip_low5 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_high5 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_low6 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_high6 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_low7 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_high7 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_low8 smallint NOT NULL DEFAULT '0',
ADD COLUMN ip_high8 smallint NOT NULL DEFAULT '0';
---#

---# Changing existing columns to ban items...
---{
upgrade_query("
ALTER TABLE {$db_prefix}ban_items
ALTER COLUMN ip_low1 type smallint,
ALTER COLUMN ip_high1 type smallint,
ALTER COLUMN ip_low2 type smallint,
ALTER COLUMN ip_high2 type smallint,
ALTER COLUMN ip_low3 type smallint,
ALTER COLUMN ip_high3 type smallint,
ALTER COLUMN ip_low4 type smallint,
ALTER COLUMN ip_high4 type smallint;");
upgrade_query("
ALTER TABLE {$db_prefix}ban_items
ALTER COLUMN ip_low1 SET DEFAULT '0',
ALTER COLUMN ip_high1 SET DEFAULT '0',
ALTER COLUMN ip_low2 SET DEFAULT '0',
ALTER COLUMN ip_high2 SET DEFAULT '0',
ALTER COLUMN ip_low3 SET DEFAULT '0',
ALTER COLUMN ip_high3 SET DEFAULT '0',
ALTER COLUMN ip_low4 SET DEFAULT '0',
ALTER COLUMN ip_high4 SET DEFAULT '0';");
upgrade_query("
ALTER TABLE {$db_prefix}ban_items
ALTER COLUMN ip_low1 SET NOT NULL,
ALTER COLUMN ip_high1 SET NOT NULL,
ALTER COLUMN ip_low2 SET NOT NULL,
ALTER COLUMN ip_high2 SET NOT NULL,
ALTER COLUMN ip_low3 SET NOT NULL,
ALTER COLUMN ip_high3 SET NOT NULL,
ALTER COLUMN ip_low4 SET NOT NULL,
ALTER COLUMN ip_high4 SET NOT NULL;");
---}
---#

/******************************************************************************/
--- Adding support for <credits> tag in package manager
/******************************************************************************/
---# Adding new columns to log_packages ..
ALTER TABLE {$db_prefix}log_packages
ADD COLUMN credits varchar(255) NOT NULL DEFAULT '';
---#

/******************************************************************************/
--- Adding more space for session ids
/******************************************************************************/
---# Altering the session_id columns...
---{
upgrade_query("
ALTER TABLE {$db_prefix}log_online
ALTER COLUMN session type varchar(64);

ALTER TABLE {$db_prefix}log_errors
ALTER COLUMN session type char(64);

ALTER TABLE {$db_prefix}sessions
ALTER COLUMN session_id type char(64);");
upgrade_query("
ALTER TABLE {$db_prefix}log_online
ALTER COLUMN session SET DEFAULT '';

ALTER TABLE {$db_prefix}log_errors
ALTER COLUMN session SET default '                                                                ';");
upgrade_query("
ALTER TABLE {$db_prefix}log_online
ALTER COLUMN session SET NOT NULL;

ALTER TABLE {$db_prefix}log_errors
ALTER COLUMN session SET NOT NULL;

ALTER TABLE {$db_prefix}sessions
ALTER COLUMN session_id SET NOT NULL;");
---}
---#

/******************************************************************************/
--- Adding new scheduled tasts
/******************************************************************************/
---# Adding new Scheduled Task...
INSERT INTO {$db_prefix}scheduled_tasks
	(next_time, time_offset, time_regularity, time_unit, disabled, task)
VALUES
	(0, 120, 1, 'd', 0, 'remove_temp_attachments');
---#
