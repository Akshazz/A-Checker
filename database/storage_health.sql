-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 24, 2026 at 05:34 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `storage_health`
--

-- --------------------------------------------------------

--
-- Table structure for table `api_keys`
--

CREATE TABLE `api_keys` (
  `id` int(11) NOT NULL,
  `label` varchar(100) NOT NULL,
  `api_key` varchar(64) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `api_keys`
--

INSERT INTO `api_keys` (`id`, `label`, `api_key`, `created_at`) VALUES
(1, 'default-agent-key', '__API_KEY__', '2026-08-24 21:26:15');

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `id` int(11) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `device_path` varchar(255) NOT NULL,
  `model` varchar(255) DEFAULT NULL,
  `serial_number` varchar(255) DEFAULT NULL,
  `interface_type` varchar(50) DEFAULT NULL,
  `drive_type` varchar(20) DEFAULT NULL,
  `first_seen` datetime DEFAULT current_timestamp(),
  `last_seen` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `devices`
--

INSERT INTO `devices` (`id`, `hostname`, `device_path`, `model`, `serial_number`, `interface_type`, `drive_type`, `first_seen`, `last_seen`) VALUES
(1, 'DESKTOP-ET32S6K', '/dev/sda', 'Ramsta SSD R600 M.2 2280 256GB', 'RLR23060700474', 'ATA', NULL, '2026-08-24 22:13:43', '2026-08-24 22:13:43'),
(2, 'DESKTOP-ET32S6K', '/dev/sdb', NULL, NULL, NULL, NULL, '2026-08-24 22:13:43', '2026-08-24 22:13:43'),
(3, 'DESKTOP-ET32S6K', '/dev/sdc', NULL, NULL, NULL, NULL, '2026-08-24 22:13:43', '2026-08-24 22:13:43'),
(4, 'DESKTOP-ET32S6K', '/dev/sdd', NULL, NULL, NULL, NULL, '2026-08-24 22:13:43', '2026-08-24 22:13:43'),
(5, 'DESKTOP-ET32S6K', '/dev/sde', NULL, NULL, NULL, NULL, '2026-08-24 22:13:43', '2026-08-24 22:13:43');

-- --------------------------------------------------------

--
-- Table structure for table `partitions`
--

CREATE TABLE `partitions` (
  `id` bigint(20) NOT NULL,
  `hostname` varchar(255) NOT NULL,
  `device_id` int(11) DEFAULT NULL,
  `disk_number` int(11) DEFAULT NULL,
  `partition_number` int(11) DEFAULT NULL,
  `drive_letter` varchar(10) DEFAULT NULL,
  `device_path` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `filesystem` varchar(50) DEFAULT NULL,
  `partition_type` varchar(100) DEFAULT NULL,
  `gpt_type` varchar(100) DEFAULT NULL,
  `mount_point` varchar(255) DEFAULT NULL,
  `size_bytes` bigint(20) UNSIGNED DEFAULT NULL,
  `free_bytes` bigint(20) UNSIGNED DEFAULT NULL,
  `usage_percent` decimal(6,2) DEFAULT NULL,
  `health` varchar(100) DEFAULT NULL,
  `recorded_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `partitions`
--

INSERT INTO `partitions` (`id`, `hostname`, `device_id`, `disk_number`, `partition_number`, `drive_letter`, `device_path`, `label`, `filesystem`, `partition_type`, `gpt_type`, `mount_point`, `size_bytes`, `free_bytes`, `usage_percent`, `health`, `recorded_at`) VALUES
(1, 'DESKTOP-ET32S6K', 1, 0, 1, NULL, NULL, NULL, NULL, 'System', '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}', NULL, 104857600, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(2, 'DESKTOP-ET32S6K', 1, 0, 2, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16777216, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(3, 'DESKTOP-ET32S6K', 1, 0, 3, 'C', NULL, 'BOOTCAMP', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 255355248640, 35478847488, 86.11, 'Healthy', '2026-08-24 22:13:43'),
(4, 'DESKTOP-ET32S6K', 1, 0, 4, NULL, NULL, '', 'NTFS', 'Recovery', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}', NULL, 580907008, 88788992, 84.72, 'Healthy', '2026-08-24 22:13:43'),
(5, 'DESKTOP-ET32S6K', 1, 1, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(6, 'DESKTOP-ET32S6K', 1, 1, 2, 'J', NULL, 'GAMES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 32735092736, 87.21, 'Healthy', '2026-08-24 22:13:43'),
(7, 'DESKTOP-ET32S6K', 1, 4, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(8, 'DESKTOP-ET32S6K', 1, 4, 2, 'F', NULL, 'GAMES2', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 512092008448, 149716316160, 70.76, 'Healthy', '2026-08-24 22:13:43'),
(9, 'DESKTOP-ET32S6K', 1, 3, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(10, 'DESKTOP-ET32S6K', 1, 3, 2, 'E', NULL, 'FILES1', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 212677423104, 47863386112, 77.49, 'Healthy', '2026-08-24 22:13:43'),
(11, 'DESKTOP-ET32S6K', 1, 3, 3, 'G', NULL, 'FILES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 222886359040, 44343164928, 80.11, 'Healthy', '2026-08-24 22:13:43'),
(12, 'DESKTOP-ET32S6K', 1, 3, 4, 'H', NULL, 'ALL FILES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 314572795904, 84152815616, 73.25, 'Healthy', '2026-08-24 22:13:43'),
(13, 'DESKTOP-ET32S6K', 1, 2, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(14, 'DESKTOP-ET32S6K', 1, 2, 2, 'D', NULL, 'GAMES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 111890972672, 56.30, 'Healthy', '2026-08-24 22:13:43'),
(15, 'DESKTOP-ET32S6K', 2, 0, 1, NULL, NULL, NULL, NULL, 'System', '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}', NULL, 104857600, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(16, 'DESKTOP-ET32S6K', 2, 0, 2, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16777216, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(17, 'DESKTOP-ET32S6K', 2, 0, 3, 'C', NULL, 'BOOTCAMP', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 255355248640, 35478847488, 86.11, 'Healthy', '2026-08-24 22:13:43'),
(18, 'DESKTOP-ET32S6K', 2, 0, 4, NULL, NULL, '', 'NTFS', 'Recovery', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}', NULL, 580907008, 88788992, 84.72, 'Healthy', '2026-08-24 22:13:43'),
(19, 'DESKTOP-ET32S6K', 2, 1, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(20, 'DESKTOP-ET32S6K', 2, 1, 2, 'J', NULL, 'GAMES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 32735092736, 87.21, 'Healthy', '2026-08-24 22:13:43'),
(21, 'DESKTOP-ET32S6K', 2, 4, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(22, 'DESKTOP-ET32S6K', 2, 4, 2, 'F', NULL, 'GAMES2', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 512092008448, 149716316160, 70.76, 'Healthy', '2026-08-24 22:13:43'),
(23, 'DESKTOP-ET32S6K', 2, 3, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(24, 'DESKTOP-ET32S6K', 2, 3, 2, 'E', NULL, 'FILES1', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 212677423104, 47863386112, 77.49, 'Healthy', '2026-08-24 22:13:43'),
(25, 'DESKTOP-ET32S6K', 2, 3, 3, 'G', NULL, 'FILES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 222886359040, 44343164928, 80.11, 'Healthy', '2026-08-24 22:13:43'),
(26, 'DESKTOP-ET32S6K', 2, 3, 4, 'H', NULL, 'ALL FILES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 314572795904, 84152815616, 73.25, 'Healthy', '2026-08-24 22:13:43'),
(27, 'DESKTOP-ET32S6K', 2, 2, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(28, 'DESKTOP-ET32S6K', 2, 2, 2, 'D', NULL, 'GAMES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 111890972672, 56.30, 'Healthy', '2026-08-24 22:13:43'),
(29, 'DESKTOP-ET32S6K', 3, 0, 1, NULL, NULL, NULL, NULL, 'System', '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}', NULL, 104857600, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(30, 'DESKTOP-ET32S6K', 3, 0, 2, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16777216, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(31, 'DESKTOP-ET32S6K', 3, 0, 3, 'C', NULL, 'BOOTCAMP', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 255355248640, 35478847488, 86.11, 'Healthy', '2026-08-24 22:13:43'),
(32, 'DESKTOP-ET32S6K', 3, 0, 4, NULL, NULL, '', 'NTFS', 'Recovery', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}', NULL, 580907008, 88788992, 84.72, 'Healthy', '2026-08-24 22:13:43'),
(33, 'DESKTOP-ET32S6K', 3, 1, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(34, 'DESKTOP-ET32S6K', 3, 1, 2, 'J', NULL, 'GAMES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 32735092736, 87.21, 'Healthy', '2026-08-24 22:13:43'),
(35, 'DESKTOP-ET32S6K', 3, 4, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(36, 'DESKTOP-ET32S6K', 3, 4, 2, 'F', NULL, 'GAMES2', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 512092008448, 149716316160, 70.76, 'Healthy', '2026-08-24 22:13:43'),
(37, 'DESKTOP-ET32S6K', 3, 3, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(38, 'DESKTOP-ET32S6K', 3, 3, 2, 'E', NULL, 'FILES1', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 212677423104, 47863386112, 77.49, 'Healthy', '2026-08-24 22:13:43'),
(39, 'DESKTOP-ET32S6K', 3, 3, 3, 'G', NULL, 'FILES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 222886359040, 44343164928, 80.11, 'Healthy', '2026-08-24 22:13:43'),
(40, 'DESKTOP-ET32S6K', 3, 3, 4, 'H', NULL, 'ALL FILES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 314572795904, 84152815616, 73.25, 'Healthy', '2026-08-24 22:13:43'),
(41, 'DESKTOP-ET32S6K', 3, 2, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(42, 'DESKTOP-ET32S6K', 3, 2, 2, 'D', NULL, 'GAMES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 111890972672, 56.30, 'Healthy', '2026-08-24 22:13:43'),
(43, 'DESKTOP-ET32S6K', 4, 0, 1, NULL, NULL, NULL, NULL, 'System', '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}', NULL, 104857600, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(44, 'DESKTOP-ET32S6K', 4, 0, 2, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16777216, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(45, 'DESKTOP-ET32S6K', 4, 0, 3, 'C', NULL, 'BOOTCAMP', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 255355248640, 35478847488, 86.11, 'Healthy', '2026-08-24 22:13:43'),
(46, 'DESKTOP-ET32S6K', 4, 0, 4, NULL, NULL, '', 'NTFS', 'Recovery', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}', NULL, 580907008, 88788992, 84.72, 'Healthy', '2026-08-24 22:13:43'),
(47, 'DESKTOP-ET32S6K', 4, 1, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(48, 'DESKTOP-ET32S6K', 4, 1, 2, 'J', NULL, 'GAMES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 32735092736, 87.21, 'Healthy', '2026-08-24 22:13:43'),
(49, 'DESKTOP-ET32S6K', 4, 4, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(50, 'DESKTOP-ET32S6K', 4, 4, 2, 'F', NULL, 'GAMES2', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 512092008448, 149716316160, 70.76, 'Healthy', '2026-08-24 22:13:43'),
(51, 'DESKTOP-ET32S6K', 4, 3, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(52, 'DESKTOP-ET32S6K', 4, 3, 2, 'E', NULL, 'FILES1', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 212677423104, 47863386112, 77.49, 'Healthy', '2026-08-24 22:13:43'),
(53, 'DESKTOP-ET32S6K', 4, 3, 3, 'G', NULL, 'FILES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 222886359040, 44343164928, 80.11, 'Healthy', '2026-08-24 22:13:43'),
(54, 'DESKTOP-ET32S6K', 4, 3, 4, 'H', NULL, 'ALL FILES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 314572795904, 84152815616, 73.25, 'Healthy', '2026-08-24 22:13:43'),
(55, 'DESKTOP-ET32S6K', 4, 2, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(56, 'DESKTOP-ET32S6K', 4, 2, 2, 'D', NULL, 'GAMES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 111890972672, 56.30, 'Healthy', '2026-08-24 22:13:43'),
(57, 'DESKTOP-ET32S6K', 5, 0, 1, NULL, NULL, NULL, NULL, 'System', '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}', NULL, 104857600, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(58, 'DESKTOP-ET32S6K', 5, 0, 2, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16777216, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(59, 'DESKTOP-ET32S6K', 5, 0, 3, 'C', NULL, 'BOOTCAMP', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 255355248640, 35478847488, 86.11, 'Healthy', '2026-08-24 22:13:43'),
(60, 'DESKTOP-ET32S6K', 5, 0, 4, NULL, NULL, '', 'NTFS', 'Recovery', '{de94bba4-06d1-4d40-a16a-bfd50179d6ac}', NULL, 580907008, 88788992, 84.72, 'Healthy', '2026-08-24 22:13:43'),
(61, 'DESKTOP-ET32S6K', 5, 1, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(62, 'DESKTOP-ET32S6K', 5, 1, 2, 'J', NULL, 'GAMES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 32735092736, 87.21, 'Healthy', '2026-08-24 22:13:43'),
(63, 'DESKTOP-ET32S6K', 5, 4, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(64, 'DESKTOP-ET32S6K', 5, 4, 2, 'F', NULL, 'GAMES2', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 512092008448, 149716316160, 70.76, 'Healthy', '2026-08-24 22:13:43'),
(65, 'DESKTOP-ET32S6K', 5, 3, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(66, 'DESKTOP-ET32S6K', 5, 3, 2, 'E', NULL, 'FILES1', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 212677423104, 47863386112, 77.49, 'Healthy', '2026-08-24 22:13:43'),
(67, 'DESKTOP-ET32S6K', 5, 3, 3, 'G', NULL, 'FILES3', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 222886359040, 44343164928, 80.11, 'Healthy', '2026-08-24 22:13:43'),
(68, 'DESKTOP-ET32S6K', 5, 3, 4, 'H', NULL, 'ALL FILES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 314572795904, 84152815616, 73.25, 'Healthy', '2026-08-24 22:13:43'),
(69, 'DESKTOP-ET32S6K', 5, 2, 1, NULL, NULL, NULL, NULL, 'Reserved', '{e3c9e316-0b5c-4db8-817d-f92df00215ae}', NULL, 16759808, NULL, NULL, NULL, '2026-08-24 22:13:43'),
(70, 'DESKTOP-ET32S6K', 5, 2, 2, 'D', NULL, 'GAMES', 'NTFS', 'Basic', '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}', NULL, 256042332160, 111890972672, 56.30, 'Healthy', '2026-08-24 22:13:43');

-- --------------------------------------------------------

--
-- Table structure for table `scans`
--

CREATE TABLE `scans` (
  `id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `scan_date` datetime DEFAULT current_timestamp(),
  `health_status` varchar(20) DEFAULT 'UNKNOWN',
  `temperature_c` int(11) DEFAULT NULL,
  `power_on_hours` int(11) DEFAULT NULL,
  `reallocated_sector_count` int(11) DEFAULT NULL,
  `pending_sector_count` int(11) DEFAULT NULL,
  `uncorrectable_sector_count` int(11) DEFAULT NULL,
  `wear_level_percent` int(11) DEFAULT NULL,
  `raw_smart_json` longtext DEFAULT NULL,
  `health_score` tinyint(3) UNSIGNED DEFAULT NULL,
  `self_test_status` varchar(255) DEFAULT NULL,
  `smart_enabled` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `scans`
--

INSERT INTO `scans` (`id`, `device_id`, `scan_date`, `health_status`, `temperature_c`, `power_on_hours`, `reallocated_sector_count`, `pending_sector_count`, `uncorrectable_sector_count`, `wear_level_percent`, `raw_smart_json`, `health_score`, `self_test_status`, `smart_enabled`) VALUES
(1, 1, '2026-08-24 22:13:43', 'FAILED', 42, 8201, 0, 0, 0, 0, '{\"json_format_version\":[1,0],\"smartctl\":{\"version\":[7,5],\"pre_release\":false,\"svn_revision\":\"5714\",\"platform_info\":\"x86_64-w64-mingw32-w10-22H2\",\"build_info\":\"(AppVeyor)\",\"argv\":[\"smartctl\",\"-a\",\"--json=c\",\"\\/dev\\/sda\",\"-d\",\"ata\"],\"exit_status\":4},\"local_time\":{\"time_t\":1787580823,\"asctime\":\"Mon Aug 24 22:13:43 2026 CST\"},\"device\":{\"name\":\"\\/dev\\/sda\",\"info_name\":\"\\/dev\\/sda\",\"type\":\"ata\",\"protocol\":\"ATA\"},\"model_name\":\"Ramsta SSD R600 M.2 2280 256GB\",\"serial_number\":\"RLR23060700474\",\"firmware_version\":\"RY26V0\",\"trim\":{\"supported\":false},\"in_smartctl_database\":false,\"smart_support\":{\"available\":true,\"enabled\":true},\"smart_status\":{\"passed\":true},\"ata_smart_data\":{\"offline_data_collection\":{\"status\":{\"value\":0,\"string\":\"was never started\"},\"completion_seconds\":120},\"self_test\":{\"status\":{\"value\":0,\"string\":\"completed without error\",\"passed\":true},\"polling_minutes\":{\"short\":2,\"extended\":4}},\"capabilities\":{\"values\":[93,2],\"exec_offline_immediate_supported\":true,\"offline_is_aborted_upon_new_cmd\":true,\"offline_surface_scan_supported\":true,\"self_tests_supported\":true,\"conveyance_self_test_supported\":false,\"selective_self_test_supported\":true,\"attribute_autosave_enabled\":false,\"error_logging_supported\":true,\"gp_logging_supported\":false}},\"ata_smart_attributes\":{\"revision\":1,\"table\":[{\"id\":1,\"name\":\"Raw_Read_Error_Rate\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":5,\"name\":\"Reallocated_Sector_Ct\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":9,\"name\":\"Power_On_Hours\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":8201,\"string\":\"8201\"}},{\"id\":12,\"name\":\"Power_Cycle_Count\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":2518,\"string\":\"2518\"}},{\"id\":160,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":161,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":100,\"string\":\"100\"}},{\"id\":163,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":32,\"string\":\"32\"}},{\"id\":164,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":469,\"string\":\"469\"}},{\"id\":165,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":630,\"string\":\"630\"}},{\"id\":166,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":453,\"string\":\"453\"}},{\"id\":167,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":514,\"string\":\"514\"}},{\"id\":168,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":169,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":100,\"string\":\"100\"}},{\"id\":175,\"name\":\"Program_Fail_Count_Chip\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":16777216,\"string\":\"16777216\"}},{\"id\":176,\"name\":\"Erase_Fail_Count_Chip\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":8427127,\"string\":\"8427127\"}},{\"id\":177,\"name\":\"Wear_Leveling_Count\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":75429332,\"string\":\"75429332\"}},{\"id\":178,\"name\":\"Used_Rsvd_Blk_Cnt_Chip\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":36,\"string\":\"36\"}},{\"id\":181,\"name\":\"Program_Fail_Cnt_Total\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":182,\"name\":\"Erase_Fail_Count_Total\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":192,\"name\":\"Power-Off_Retract_Count\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":41,\"string\":\"41\"}},{\"id\":194,\"name\":\"Temperature_Celsius\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":42,\"string\":\"42\"}},{\"id\":195,\"name\":\"Hardware_ECC_Recovered\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":196,\"name\":\"Reallocated_Event_Count\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":197,\"name\":\"Current_Pending_Sector\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":198,\"name\":\"Offline_Uncorrectable\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":199,\"name\":\"UDMA_CRC_Error_Count\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":0,\"string\":\"0\"}},{\"id\":232,\"name\":\"Available_Reservd_Space\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":100,\"string\":\"100\"}},{\"id\":241,\"name\":\"Total_LBAs_Written\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":485534,\"string\":\"485534\"}},{\"id\":242,\"name\":\"Total_LBAs_Read\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":939258,\"string\":\"939258\"}},{\"id\":245,\"name\":\"Unknown_Attribute\",\"value\":100,\"worst\":100,\"flags\":{\"value\":50,\"string\":\"-O--CK \",\"prefailure\":false,\"updated_online\":true,\"performance\":false,\"error_rate\":false,\"event_count\":true,\"auto_keep\":true},\"raw\":{\"value\":2376034,\"string\":\"2376034\"}}]},\"spare_available\":{\"current_percent\":100},\"power_on_time\":{\"hours\":8201},\"power_cycle_count\":2518,\"endurance_used\":{\"current_percent\":0},\"temperature\":{\"current\":42}}', 0, 'completed without error', 1),
(2, 2, '2026-08-24 22:13:43', 'UNKNOWN', NULL, NULL, NULL, NULL, NULL, NULL, '{\"json_format_version\":[1,0],\"smartctl\":{\"version\":[7,5],\"pre_release\":false,\"svn_revision\":\"5714\",\"platform_info\":\"x86_64-w64-mingw32-w10-22H2\",\"build_info\":\"(AppVeyor)\",\"argv\":[\"smartctl\",\"-a\",\"--json=c\",\"\\/dev\\/sdb\",\"-d\",\"sat\"],\"messages\":[{\"string\":\"Smartctl open device: \\/dev\\/sdb [SAT] failed: \\\\\\\\.\\\\PhysicalDrive1: Open failed, Error=5\",\"severity\":\"error\"}],\"exit_status\":2},\"local_time\":{\"time_t\":1787580823,\"asctime\":\"Mon Aug 24 22:13:43 2026 CST\"}}', 100, NULL, NULL),
(3, 3, '2026-08-24 22:13:43', 'UNKNOWN', NULL, NULL, NULL, NULL, NULL, NULL, '{\"json_format_version\":[1,0],\"smartctl\":{\"version\":[7,5],\"pre_release\":false,\"svn_revision\":\"5714\",\"platform_info\":\"x86_64-w64-mingw32-w10-22H2\",\"build_info\":\"(AppVeyor)\",\"argv\":[\"smartctl\",\"-a\",\"--json=c\",\"\\/dev\\/sdc\",\"-d\",\"sat\"],\"messages\":[{\"string\":\"Smartctl open device: \\/dev\\/sdc [SAT] failed: \\\\\\\\.\\\\PhysicalDrive2: Open failed, Error=5\",\"severity\":\"error\"}],\"exit_status\":2},\"local_time\":{\"time_t\":1787580823,\"asctime\":\"Mon Aug 24 22:13:43 2026 CST\"}}', 100, NULL, NULL),
(4, 4, '2026-08-24 22:13:43', 'UNKNOWN', NULL, NULL, NULL, NULL, NULL, NULL, '{\"json_format_version\":[1,0],\"smartctl\":{\"version\":[7,5],\"pre_release\":false,\"svn_revision\":\"5714\",\"platform_info\":\"x86_64-w64-mingw32-w10-22H2\",\"build_info\":\"(AppVeyor)\",\"argv\":[\"smartctl\",\"-a\",\"--json=c\",\"\\/dev\\/sdd\",\"-d\",\"sat\"],\"messages\":[{\"string\":\"Smartctl open device: \\/dev\\/sdd [SAT] failed: \\\\\\\\.\\\\PhysicalDrive3: Open failed, Error=5\",\"severity\":\"error\"}],\"exit_status\":2},\"local_time\":{\"time_t\":1787580823,\"asctime\":\"Mon Aug 24 22:13:43 2026 CST\"}}', 100, NULL, NULL),
(5, 5, '2026-08-24 22:13:43', 'UNKNOWN', NULL, NULL, NULL, NULL, NULL, NULL, '{\"json_format_version\":[1,0],\"smartctl\":{\"version\":[7,5],\"pre_release\":false,\"svn_revision\":\"5714\",\"platform_info\":\"x86_64-w64-mingw32-w10-22H2\",\"build_info\":\"(AppVeyor)\",\"argv\":[\"smartctl\",\"-a\",\"--json=c\",\"\\/dev\\/sde\",\"-d\",\"sat\"],\"messages\":[{\"string\":\"Smartctl open device: \\/dev\\/sde [SAT] failed: \\\\\\\\.\\\\PhysicalDrive4: Open failed, Error=5\",\"severity\":\"error\"}],\"exit_status\":2},\"local_time\":{\"time_t\":1787580823,\"asctime\":\"Mon Aug 24 22:13:43 2026 CST\"}}', 100, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `api_keys`
--
ALTER TABLE `api_keys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `api_key` (`api_key`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_device` (`hostname`,`serial_number`,`device_path`);

--
-- Indexes for table `partitions`
--
ALTER TABLE `partitions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_part_host` (`hostname`),
  ADD KEY `idx_part_recorded` (`recorded_at`);

--
-- Indexes for table `scans`
--
ALTER TABLE `scans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_device_date` (`device_id`,`scan_date`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `api_keys`
--
ALTER TABLE `api_keys`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `partitions`
--
ALTER TABLE `partitions`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT for table `scans`
--
ALTER TABLE `scans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `scans`
--
ALTER TABLE `scans`
  ADD CONSTRAINT `scans_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
