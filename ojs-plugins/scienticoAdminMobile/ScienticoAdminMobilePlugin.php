<?php

/**
 * Plugin responsif halaman pengelolaan ScientiCO.
 */

namespace APP\plugins\generic\scienticoAdminMobile;

use APP\core\Application;
use PKP\plugins\GenericPlugin;
use PKP\plugins\Hook;

class ScienticoAdminMobilePlugin extends GenericPlugin
{
    /**
     * Daftarkan aset ketika plugin aktif.
     *
     * @param string $category
     * @param string $path
     * @param mixed $mainContextId
     */
    public function register($category, $path, $mainContextId = null)
    {
        if (!parent::register($category, $path, $mainContextId)) {
            return false;
        }

        if ($this->getEnabled($mainContextId)) {
            Hook::add(
                'TemplateManager::display',
                $this->addBackendAssets(...)
            );
        }

        return true;
    }

    /**
     * Nama plugin.
     */
    public function getDisplayName()
    {
        return 'ScientiCO Admin Mobile';
    }

    /**
     * Deskripsi plugin.
     */
    public function getDescription()
    {
        return 'Mengubah navigasi samping dashboard ScientiCO menjadi drawer hamburger pada perangkat seluler.';
    }

    /**
     * Muat CSS dan JavaScript pada halaman backend.
     *
     * @param string $hookName
     * @param array $args
     */
    public function addBackendAssets($hookName, $args)
    {
        $templateManager = $args[0];
        $request = Application::get()->getRequest();

        $pluginUrl = sprintf(
            '%s/%s',
            rtrim($request->getBaseUrl(), '/'),
            trim($this->getPluginPath(), '/')
        );

        $templateManager->addStyleSheet(
            'scienticoAdminMobile',
            $pluginUrl . '/styles/admin-mobile.css?v=1.2.0',
            [
                'contexts' => ['backend'],
                'priority' => 20,
            ]
        );

        $templateManager->addJavaScript(
            'scienticoAdminMobile',
            $pluginUrl . '/js/admin-mobile.js?v=1.2.0',
            [
                'inline' => false,
                'contexts' => ['backend'],
                'priority' => 20,
            ]
        );

        return false;
    }
}