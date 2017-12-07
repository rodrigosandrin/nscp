/*
 * Copyright (C) 2004-2016 Michael Medin
 *
 * This file is part of NSClient++ - https://nsclient.org
 *
 * NSClient++ is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * NSClient++ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with NSClient++.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "schedules_handler.hpp"

#include <scheduler/simple_scheduler.hpp>

#include <nscapi/nscapi_plugin_impl.hpp>
#include <nscapi/nscapi_protobuf.hpp>


typedef schedules::schedule_handler::object_instance schedule_instance;
class Scheduler : public schedules::task_handler, public nscapi::impl::simple_plugin {
private:

	schedules::scheduler scheduler_;
	schedules::schedule_handler schedules_;

public:
	Scheduler() {
		scheduler_.set_handler(this);
	}
	virtual ~Scheduler() {
		scheduler_.set_handler(NULL);
	}
	// Module calls
	bool loadModuleEx(std::string alias, NSCAPI::moduleLoadMode mode);
	bool unloadModule();

	// Metrics
	void fetchMetrics(Plugin::MetricsMessage_Response *response);

	bool commandLineExec(const int target_mode, const Plugin::ExecuteRequestMessage::Request &request, Plugin::ExecuteResponseMessage::Response *response, const Plugin::ExecuteRequestMessage &request_message);

	void add_schedule(std::string alias, std::string command);
	bool handle_schedule(const schedules::task_container &item);

	void on_error(const char* file, int line, std::string error);
	void on_trace(const char* file, int line, std::string error);


	bool on_cli_add(const Plugin::ExecuteRequestMessage_Request &request, Plugin::ExecuteResponseMessage_Response *response);
};