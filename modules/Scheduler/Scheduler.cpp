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

#include "Scheduler.h"

#include <nscapi/nscapi_core_helper.hpp>
#include <nscapi/nscapi_helper_singleton.hpp>
#include <nscapi/nscapi_settings_helper.hpp>
#include <nscapi/nscapi_protobuf.hpp>
#include <nscapi/nscapi_protobuf_nagios.hpp>
#include <nscapi/nscapi_program_options.hpp>
#include <nscapi/macros.hpp>

#include <boost/program_options.hpp>


namespace sh = nscapi::settings_helper;

bool Scheduler::loadModuleEx(std::string alias, NSCAPI::moduleLoadMode mode) {
	if (mode == NSCAPI::reloadStart) {
		scheduler_.prepare_shutdown();
		scheduler_.unset_handler();
		scheduler_.stop();
		schedules_.clear();
	}


	sh::settings_registry settings(get_settings_proxy());
	settings.set_alias(alias, "scheduler");
	schedules_.set_path(settings.alias().get_settings_path("schedules"));

	settings.alias().add_path_to_settings()
		("Scheduler", "Section for the Scheduler module.")

		;

	settings.alias().add_key_to_settings()
		("threads", sh::int_fun_key(boost::bind(&schedules::scheduler::set_threads, &scheduler_, _1), 5),
			"Threads", "Number of threads to use.")
		;

	settings.alias().add_path_to_settings()
		("schedules", sh::fun_values_path(boost::bind(&Scheduler::add_schedule, this, _1, _2)),
			"Schedules", "Section for the Scheduler module.",
			"SCHEDULE", "For more configuration options add a dedicated section")
		;

	settings.alias().add_templates()
		("schedules", "plus", "Add a simple schedule",
			"Add a simple scheduled job for passive monitoring",
			"{"
			"\"fields\": [ "
			" { \"id\": \"alias\",		\"title\" : \"Alias\",		\"type\" : \"input\",		\"desc\" : \"This will identify the command\"} , "
			" { \"id\": \"command\",	\"title\" : \"Command\",	\"type\" : \"data-choice\",	\"desc\" : \"The name of the command to execute\",\"exec\" : \"CheckExternalScripts list --json --query\" } , "
			" { \"id\": \"args\",		\"title\" : \"Arguments\",	\"type\" : \"input\",		\"desc\" : \"Command line arguments for the command\" } , "
			" { \"id\": \"cmd\",		\"key\" : \"command\", \"title\" : \"A\",	\"type\" : \"hidden\",		\"desc\" : \"A\" } "
			" ], "
			"\"events\": { "
			"\"onSave\": \"(function (node) { node.save_path = self.path; var f = node.get_field('cmd'); f.key = node.get_field('alias').value(); var val = node.get_field('command').value(); if (node.get_field('args').value()) { val += ' ' + node.get_field('args').value(); }; f.value(val)})\""
			"}"
			"}")
		;
	settings.register_all();
	settings.notify();

	schedules_.ensure_default();
	schedules_.add_samples(get_settings_proxy());

	BOOST_FOREACH(const schedules::schedule_handler::object_list_type::value_type &o, schedules_.get_object_list()) {
		if (o->duration && (*o->duration).total_seconds() == 0) {
			NSC_LOG_ERROR("WE cant add schedules with 0 duration: " + o->to_string());
			continue;
		}
		if (o->duration && o->schedule) {
			NSC_LOG_ERROR("WE cant add schedules with both duration and schedule: " + o->to_string());
			continue;
		}
		if (!o->duration && !o->schedule) {
			NSC_LOG_ERROR("WE need wither duration or schedule: " + o->to_string());
			continue;
		}
		NSC_DEBUG_MSG("Adding scheduled item: " + o->to_string());
		scheduler_.add_task(o);
	}

	if (mode == NSCAPI::normalStart) {
		scheduler_.set_handler(this);
		scheduler_.start();
	}
	if (mode == NSCAPI::reloadStart) {
		scheduler_.set_handler(this);
		scheduler_.start();
	}
	return true;
}

void Scheduler::add_schedule(std::string key, std::string arg) {
	try {
		schedules_.add(get_settings_proxy(), key, arg);
	} catch (const std::exception &e) {
		NSC_LOG_ERROR_EXR("Failed to add target: " + key, e);
	} catch (...) {
		NSC_LOG_ERROR_EX("Failed to add target: " + key);
	}
}

bool Scheduler::unloadModule() {
	scheduler_.prepare_shutdown();
	scheduler_.unset_handler();
	scheduler_.stop();
	schedules_.clear();
	return true;
}

void Scheduler::on_error(const char* file, int line, std::string msg) {
	GET_CORE()->log(NSCAPI::log_level::error, file, line, msg);
}
void Scheduler::on_trace(const char* file, int line, std::string msg) {
	GET_CORE()->log(NSCAPI::log_level::trace, file, line, msg);
}

#include <nscapi/functions.hpp>


bool Scheduler::handle_schedule(const schedules::task_container &item) {
	try {
		std::string response;
		nscapi::core_helper ch(get_core(), get_id());
		if (!ch.simple_query(item.command, item.arguments, response)) {
			NSC_LOG_ERROR("Failed to execute: " + item.command);
			if (item.channel.empty()) {
				NSC_LOG_ERROR("No channel specified for " + item.alias);
				return true;
			}
			nscapi::protobuf::functions::create_simple_submit_request(item.channel, item.command, NSCAPI::query_return_codes::returnUNKNOWN, "Command was not found: " + item.command, "", response);
			std::string result;
			get_core()->submit_message(item.channel, response, result);
			return true;
		}
		Plugin::QueryResponseMessage resp_msg;
		resp_msg.ParseFromString(response);
		Plugin::QueryResponseMessage resp_msg_send;
		resp_msg_send.mutable_header()->CopyFrom(resp_msg.header());
		BOOST_FOREACH(const Plugin::QueryResponseMessage::Response &p, resp_msg.payload()) {
			if (nscapi::report::matches(item.report, nscapi::protobuf::functions::gbp_to_nagios_status(p.result())))
				resp_msg_send.add_payload()->CopyFrom(p);
		}
		if (resp_msg_send.payload_size() > 0) {
			if (item.channel.empty()) {
				NSC_LOG_ERROR_STD("No channel specified for " + item.alias + " mssage will not be sent.");
				return true;
			}
			nscapi::protobuf::functions::make_submit_from_query(response, item.channel, item.alias, item.target_id, item.source_id);
			std::string result;
			if (!get_core()->submit_message(item.channel, response, result)) {
				NSC_LOG_ERROR_STD("Failed to submit: " + item.alias);
				return true;
			}
			std::string error;
			if (!nscapi::protobuf::functions::parse_simple_submit_response(result, error)) {
				NSC_LOG_ERROR_STD("Failed to submit " + item.alias + ": " + error);
				return true;
			}
		} else {
			NSC_DEBUG_MSG("Filter not matched for: " + item.alias + " so nothing is reported");
		}
		return true;
	} catch (nsclient::nsclient_exception &e) {
		NSC_LOG_ERROR_EXR("Failed to register command: ", e);
		return false;
	} catch (std::exception &e) {
		NSC_LOG_ERROR_EXR("Exception: ", e);
		return false;
	} catch (...) {
		NSC_LOG_ERROR_EX(item.alias);
		return false;
	}
}

void Scheduler::fetchMetrics(Plugin::MetricsMessage::Response *response) {
	Plugin::Common::MetricsBundle *bundle = response->add_bundles();
	bundle->set_key("scheduler");
	if (scheduler_.get_scheduler().has_metrics()) {
		boost::uint64_t taskes__ = scheduler_.get_scheduler().get_metric_executed();
		boost::uint64_t submitted__ = scheduler_.get_scheduler().get_metric_compleated();
		boost::uint64_t errors__ = scheduler_.get_scheduler().get_metric_errors();
		boost::uint64_t threads = scheduler_.get_scheduler().get_metric_threads();
		boost::uint64_t queue = scheduler_.get_scheduler().get_metric_ql();

		Plugin::Common::Metric *m = bundle->add_value();
		m->set_key("jobs");
		m->mutable_value()->set_int_data(taskes__);
		m = bundle->add_value();
		m->set_key("submitted");
		m->mutable_value()->set_int_data(submitted__);
		m = bundle->add_value();
		m->set_key("errors");
		m->mutable_value()->set_int_data(errors__);
		m = bundle->add_value();
		m->set_key("threads");
		m->mutable_value()->set_int_data(threads);
		m = bundle->add_value();
		m->set_key("queue");
		m->mutable_value()->set_int_data(queue);
	} else {
		Plugin::Common::Metric *m = bundle->add_value();
		m->set_key("metrics.available");
		m->mutable_value()->set_string_data("false");
	}
}

bool Scheduler::on_cli_add(const Plugin::ExecuteRequestMessage_Request &request, Plugin::ExecuteResponseMessage_Response *response) {
	namespace po = boost::program_options;
	namespace pf = nscapi::protobuf::functions;
	po::variables_map vm;
	po::options_description desc;
	std::string alias, command, interval;

	desc.add_options()
		("help", "Show help.")

		("interval", po::value<std::string>(&interval)->required(),
		"The interval")
		("command", po::value<std::string>(&command)->required(),
		"The command")
		("alias", po::value<std::string>(&alias)->required(),
		"The alias")
		;

	try {
		nscapi::program_options::basic_command_line_parser cmd(request);
		cmd.options(desc);

		po::parsed_options parsed = cmd.run();
		po::store(parsed, vm);
		po::notify(vm);

		if (vm.count("help")) {
			nscapi::protobuf::functions::set_response_good(*response, nscapi::program_options::help(desc));
			return true;
		}

		std::list<std::string> args;
		schedules::task_container c(0, alias, command, args, "op5");
		scheduler_.add_task(c, interval);

		return true;
	} catch (const std::exception &e) {
		nscapi::program_options::invalid_syntax(desc, request.command(), "Invalid command line: " + utf8::utf8_from_native(e.what()), *response);
		return true;
	} catch (...) {
		nscapi::program_options::invalid_syntax(desc, request.command(), "Unknown exception", *response);
		return true;
	}

}

bool Scheduler::commandLineExec(const int target_mode, const Plugin::ExecuteRequestMessage::Request &request, Plugin::ExecuteResponseMessage::Response *response, const Plugin::ExecuteRequestMessage &request_message) {
	std::string command = request.command();
	if (command.empty() && target_mode == NSCAPI::target_module && request.arguments_size() > 0)
		command = request.arguments(0);
	else if (command.empty() && target_mode == NSCAPI::target_module)
		command = "help";
	try {
		if (command == "help") {
			nscapi::protobuf::functions::set_response_bad(*response, "Usage: nscp scheduler [add] --help");
		} else {
			if (command == "add") {
				on_cli_add(request, response);
				return true;
			}
			return false;
		}
	} catch (const std::exception &e) {
		nscapi::protobuf::functions::set_response_bad(*response, "Error: " + utf8::utf8_from_native(e.what()));
	} catch (...) {
		nscapi::protobuf::functions::set_response_bad(*response, "Error: ");
	}
	return false;

}
