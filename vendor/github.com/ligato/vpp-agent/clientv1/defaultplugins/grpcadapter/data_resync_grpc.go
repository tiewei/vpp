// Copyright (c) 2017 Cisco and/or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package grpcadapter

import (
	"strconv"

	"github.com/ligato/cn-infra/db/keyval"
	"github.com/ligato/vpp-agent/clientv1/defaultplugins"
	"github.com/ligato/vpp-agent/flavors/rpc/model/vppsvc"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/acl"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/bfd"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/interfaces"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/l2"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/l3"
	"github.com/ligato/vpp-agent/plugins/defaultplugins/common/model/l4"
	"golang.org/x/net/context"
)

// NewDataResyncDSL is a constructor.
func NewDataResyncDSL(client vppsvc.ResyncConfigServiceClient) *DataResyncDSL {
	return &DataResyncDSL{client,
		map[string] /*name*/ *interfaces.Interfaces_Interface{},
		map[string] /*name*/ *bfd.SingleHopBFD_Session{},
		map[uint32] /*id*/ *bfd.SingleHopBFD_Key{},
		map[string] /*name*/ *bfd.SingleHopBFD_EchoFunction{},
		map[string] /*name*/ *l2.BridgeDomains_BridgeDomain{},
		map[string] /*key*/ *l2.FibTableEntries_FibTableEntry{},
		map[string] /*name*/ *l2.XConnectPairs_XConnectPair{},
		map[string] /*key*/ *l3.StaticRoutes_Route{},
		map[string] /*name*/ *acl.AccessLists_Acl{},
		map[string] /*id*/ *l4.L4Features{},
		map[string] /*value*/ *l4.AppNamespaces_AppNamespace{},
	}
}

// DataResyncDSL is used to conveniently assign all the data that are needed for the RESYNC.
// This is implementation of Domain Specific Language (DSL) for data RESYNC of the VPP configuration.
type DataResyncDSL struct {
	client            vppsvc.ResyncConfigServiceClient
	txnPutIntf        map[string] /*name*/ *interfaces.Interfaces_Interface
	txnPutBfdSession  map[string] /*name*/ *bfd.SingleHopBFD_Session
	txnPutBfdAuthKey  map[uint32] /*id*/ *bfd.SingleHopBFD_Key
	txnPutBfdEcho     map[string] /*name*/ *bfd.SingleHopBFD_EchoFunction
	txnPutBD          map[string] /*name*/ *l2.BridgeDomains_BridgeDomain
	txnPutBDFIB       map[string] /*key*/ *l2.FibTableEntries_FibTableEntry
	txnPutXCon        map[string] /*name*/ *l2.XConnectPairs_XConnectPair
	txnPutStaticRoute map[string] /*key*/ *l3.StaticRoutes_Route
	txnPutACL         map[string] /*name*/ *acl.AccessLists_Acl
	txnPutL4Features  map[string] /*value*/ *l4.L4Features
	txnPutAppNs       map[string] /*id*/ *l4.AppNamespaces_AppNamespace
}

// Interface adds Bridge Domain to the RESYNC request.
func (dsl *DataResyncDSL) Interface(val *interfaces.Interfaces_Interface) defaultplugins.DataResyncDSL {
	dsl.txnPutIntf[val.Name] = val

	return dsl
}

// BfdSession adds BFD session to the RESYNC request.
func (dsl *DataResyncDSL) BfdSession(val *bfd.SingleHopBFD_Session) defaultplugins.DataResyncDSL {
	dsl.txnPutBfdSession[val.Interface] = val

	return dsl
}

// BfdAuthKeys adds BFD key to the RESYNC request.
func (dsl *DataResyncDSL) BfdAuthKeys(val *bfd.SingleHopBFD_Key) defaultplugins.DataResyncDSL {
	dsl.txnPutBfdAuthKey[val.Id] = val

	return dsl
}

// BfdEchoFunction adds BFD echo function to the RESYNC request.
func (dsl *DataResyncDSL) BfdEchoFunction(val *bfd.SingleHopBFD_EchoFunction) defaultplugins.DataResyncDSL {
	dsl.txnPutBfdEcho[val.EchoSourceInterface] = val

	return dsl
}

// BD adds Bridge Domain to the RESYNC request.
func (dsl *DataResyncDSL) BD(val *l2.BridgeDomains_BridgeDomain) defaultplugins.DataResyncDSL {
	dsl.txnPutBD[val.Name] = val

	return dsl
}

// BDFIB adds Bridge Domain to the RESYNC request.
func (dsl *DataResyncDSL) BDFIB(val *l2.FibTableEntries_FibTableEntry) defaultplugins.DataResyncDSL {
	dsl.txnPutBDFIB[l2.FibKey(val.BridgeDomain, val.PhysAddress)] = val

	return dsl
}

// XConnect adds Cross Connect to the RESYNC request.
func (dsl *DataResyncDSL) XConnect(val *l2.XConnectPairs_XConnectPair) defaultplugins.DataResyncDSL {
	dsl.txnPutXCon[val.ReceiveInterface] = val

	return dsl
}

// StaticRoute adds L3 Static Route to the RESYNC request.
func (dsl *DataResyncDSL) StaticRoute(val *l3.StaticRoutes_Route) defaultplugins.DataResyncDSL {
	dsl.txnPutStaticRoute[l3.RouteKey(val.VrfId, val.DstIpAddr, val.NextHopAddr)] = val

	return dsl
}

// ACL adds Access Control List to the RESYNC request.
func (dsl *DataResyncDSL) ACL(val *acl.AccessLists_Acl) defaultplugins.DataResyncDSL {
	dsl.txnPutACL[val.AclName] = val

	return dsl
}

// L4Features adds L4Features to the RESYNC request.
func (dsl *DataResyncDSL) L4Features(val *l4.L4Features) defaultplugins.DataResyncDSL {
	dsl.txnPutL4Features[strconv.FormatBool(val.Enabled)] = val

	return dsl
}

// AppNamespace adds Application Namespace to the RESYNC request.
func (dsl *DataResyncDSL) AppNamespace(val *l4.AppNamespaces_AppNamespace) defaultplugins.DataResyncDSL {
	dsl.txnPutAppNs[val.NamespaceId] = val

	return dsl
}

// AppendKeys is a helper function that fills the keySet with iterator values.
func appendKeys(keys *keySet, it keyval.ProtoKeyIterator) {
	for {
		k, _, stop := it.GetNext()
		if stop {
			break
		}

		(*keys)[k] = nil
	}
}

// KeySet is a helper type that reuses the map keys to store the set values. The values of the map are nil.
type keySet map[string] /*key*/ interface{} /*nil*/

// Send propagates the request to the plugins. It deletes obsolete keys if listKeys() function is not null.
// The listkeys() function is used to list all current keys.
func (dsl *DataResyncDSL) Send() defaultplugins.Reply {
	putIntfs := []*interfaces.Interfaces_Interface{}
	for _, intf := range dsl.txnPutIntf {
		putIntfs = append(putIntfs, intf)
	}
	putBDs := []*l2.BridgeDomains_BridgeDomain{}
	for _, bd := range dsl.txnPutBD {
		putBDs = append(putBDs, bd)
	}
	putXCons := []*l2.XConnectPairs_XConnectPair{}
	for _, xcon := range dsl.txnPutXCon {
		putXCons = append(putXCons, xcon)
	}
	putRoutes := []*l3.StaticRoutes_Route{}
	for _, route := range dsl.txnPutStaticRoute {
		putRoutes = append(putRoutes, route)
	}
	putACLs := []*acl.AccessLists_Acl{}
	for _, acl := range dsl.txnPutACL {
		putACLs = append(putACLs, acl)
	}

	_, err := dsl.client.ResyncConfig(context.Background(), &vppsvc.ResyncConfigRequest{
		Interfaces:   &interfaces.Interfaces{Interface: putIntfs},
		BDs:          &l2.BridgeDomains{BridgeDomains: putBDs},
		XCons:        &l2.XConnectPairs{XConnectPairs: putXCons},
		ACLs:         &acl.AccessLists{Acl: putACLs},
		StaticRoutes: &l3.StaticRoutes{Route: putRoutes},
	})

	return &Reply{err: err}
}
