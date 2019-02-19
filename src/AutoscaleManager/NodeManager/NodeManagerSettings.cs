// ------------------------------------------------------------
//  Copyright (c) Microsoft Corporation.  All rights reserved.
//  Licensed under the MIT License (MIT). See LICENSE in the repo root for license information.
// ------------------------------------------------------------

namespace NodeManager
{
    using System;
    using System.Fabric.Description;

    internal class NodeManagerSettings
    {
        private const string sectionName = "NodeManagerSettings";
        private const int defaultScanIntervalInSeconds = 60;
        private const int defaultClientOperationTimeoutInSeconds = 30;
        private const int defaultDownNodeGraceIntervalInSeconds = 120;
        private const bool defaultSkipNodesUnderFabricUpgrade = true;

        public NodeManagerSettings(ConfigurationSettings settings)
        {
            settings.Sections.TryGetValue(sectionName, out var configSection);

            this.ScanInterval = TimeSpan.FromSeconds(GetValueFromSection(configSection, "ScanIntervalInSeconds", defaultScanIntervalInSeconds));
            this.ClientOperationTimeout = TimeSpan.FromSeconds(GetValueFromSection(configSection, "ClientOperationTimeoutInSeconds", defaultClientOperationTimeoutInSeconds));
            this.DownNodeGraceInterval = TimeSpan.FromSeconds(GetValueFromSection(configSection, "DownNodeGraceIntervalInSeconds", defaultDownNodeGraceIntervalInSeconds));
            this.SkipNodesUnderFabricUpgrade = GetValueFromSection(configSection, "SkipNodesUnderFabricUpgrade", defaultSkipNodesUnderFabricUpgrade);
        }

        public TimeSpan ScanInterval { get; }

        public TimeSpan ClientOperationTimeout { get; }

        public TimeSpan DownNodeGraceInterval { get; }

        public bool SkipNodesUnderFabricUpgrade { get; }

        private int GetValueFromSection(ConfigurationSection configSection, string parameter, int defaultValue)
        {
            string parameterValue = GetValueFromSection(configSection, parameter);

            if (int.TryParse(parameterValue, out var val))
            {
                return val;
            }

            return defaultValue;
        }

        private bool GetValueFromSection(ConfigurationSection configSection, string parameter, bool defaultValue)
        {
            string parameterValue = GetValueFromSection(configSection, parameter);

            if (bool.TryParse(parameterValue, out var boolVal))
            {
                return boolVal;
            }

            return defaultValue;
        }

        private string GetValueFromSection(ConfigurationSection configSection, string parameter, string defaultValue = "")
        {
            if (configSection == null)
            {
                return defaultValue;
            }

            if (configSection.Parameters.TryGetValue(parameter, out var val))
            {
                return val.Value;
            }

            return defaultValue;
        }
    }
}
