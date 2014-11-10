module GlobalErrorHandler
  module Server
    GEH_VIEW_PATH   = File.join(File.dirname(__FILE__), 'server', 'views')
    GEH_PUBLIC_PATH = File.join(File.dirname(__FILE__), 'server', 'public')

    def self.registered(app)
      app.get '/exceptions' do
        key = params.keys.first
        if %w(js css).include? key
          geh_public_view params[key], key
        else
          prepare_and_show_index_action
        end
      end

      app.get '/exceptions/filter/:filter_by/:filter' do
        prepare_and_show_index_action
      end

      app.get '/exceptions/:id' do
        @app_exception = GlobalErrorHandler::AppException.find(params[:id])
        show_view :show
      end

      app.delete '/exceptions/filter/:filter_by/:filter/truncate' do
        truncate_and_redirect_to_exceptions
      end

      app.delete '/exceptions/truncate' do
        truncate_and_redirect_to_exceptions
      end

      app.delete '/exceptions/delete' do
        GlobalErrorHandler::AppException.delete_all(params[:app_exception_delete_ids])
        redirect_to_exceptions
      end

      app.delete '/exceptions/:id' do
        GlobalErrorHandler::AppException.delete(params[:id])
        redirect_to_exceptions
      end

      app.tabs << 'Exceptions'

      app.helpers do
        include ActionView::Helpers::TextHelper #link_to
        include ActionView::Helpers::UrlHelper #simple_format
        include ActionView::Helpers::FormHelper #select_tag check_box_tag
        include ActionView::Helpers::FormOptionsHelper #options_for_select
        include ActionView::Helpers::OutputSafetyHelper #delete via ajax

        def prepare_and_show_index_action
          @app_exceptions = GlobalErrorHandler::AppException.all(params[:start], params[:filter_by], get_filter)
          @all_classes = GlobalErrorHandler::AppException.filters_for('class')
          @all_messages = GlobalErrorHandler::AppException.filters_for('message')
          show_view :index
        end

        def truncate_and_redirect_to_exceptions
          GlobalErrorHandler::AppException.truncate(get_filter, field: params[:filter_by])
          redirect exceptions_path
        end

        def redirect_to_exceptions
          redirect exceptions_path(params[:start], params[:filter_by], params[:filter])
        end

        def show_view(filename = :index)
          erb haml( File.read(File.join(GEH_VIEW_PATH, "#{filename}.html.haml")) )
        end

        def geh_public_view(filename, dir='')
          file = File.join(GEH_PUBLIC_PATH, dir, filename)
          begin
            cache_control :public, max_age: 1800
            send_file file
          rescue Errno::ENOENT
            404
          end
        end

        def exceptions_path(start = nil, filter_by = nil, filter = nil)
          path = "/resque/exceptions"
          path += "/filter/#{filter_by}/#{URI.escape(filter)}" if filter_by && filter
          path += "?start=#{start}" if start
          path
        end

        def exception_path(id, start=nil, filter_by = nil, filter = nil)
          path = "/resque/exceptions/#{id}"
          path_params = []
          path_params.push "start=#{start}" if start
          path_params.push "filter_by=#{filter_by}&filter=#{URI.escape(filter)}" if filter_by && filter
          path += '?' + path_params.join('&') if path_params.size > 0
          path
        end

        def apps_size
          @apps_size ||= GlobalErrorHandler::AppException.count(params[:filter_by], get_filter).to_i
        end

        def apps_start_at
          return 0 if apps_size < 1
          params[:start].to_i + 1
        end

        def apps_per_page
          10
        end

        def apps_end_at
          if apps_start_at + apps_per_page > apps_size
            apps_size
          else
            apps_start_at + apps_per_page - 1
          end
        end

        def each_app_exception(&block)
          return unless block_given?
          @app_exceptions.try(:each) do |app_exception|
            yield app_exception
          end
        end

        def pagination(options = {})
          start    = options[:start] || 0
          per_page = apps_per_page
          total    = options[:total] || 0
          return if total < per_page

          markup = ""
          if start - per_page >= 0
            markup << link_to(raw("&laquo; less"), exceptions_path(start - per_page), class: 'btn less')
          elsif start > 0 && start < per_page
            markup << link_to(raw("&laquo; less"), exceptions_path(0), class: 'btn less')
          end

          markup << pages_markup(start, per_page, total)

          if start + per_page < total
            markup << link_to(raw("more &raquo;"), exceptions_path(start + per_page), class: 'btn more')
          end
          markup
        end

        def pages_markup(start, per_page, total)
          pages_count = ((total - 1) / per_page).ceil
          return '' if pages_count < 1

          left_ind = start / per_page
          markups = [left_ind.to_s]
          while (left_ind -= 1) >= 0 && (start/per_page - left_ind <= max_side_links || pages_count < max_links)
            markups.unshift link_to(left_ind, exceptions_path(left_ind * per_page, params[:filter_by], params[:filter]), class: 'btn pages')
          end
          right_ind = start / per_page
          if right_ind > max_side_links && pages_count >= max_links
            markups.unshift '...' if right_ind - max_side_links > 1
            markups.unshift link_to(0, exceptions_path(0, params[:filter_by], params[:filter]), class: 'btn pages')
          end
          while (right_ind +=1) * per_page < total && (right_ind - start / per_page <= max_side_links || pages_count < max_links)
            markups.push link_to(right_ind, exceptions_path(per_page * right_ind, params[:filter_by], params[:filter]), class: 'btn pages')
          end
          if pages_count >= max_links && pages_count >= right_ind
            markups.push '...' if pages_count - right_ind >= 1
            markups.push link_to(pages_count, exceptions_path(pages_count * per_page, params[:filter_by], params[:filter]), class: 'btn pages')
          end
          markups.join(' ')
        end

        def max_side_links
          4
        end

        def max_links
          max_side_links * 2 + 1
        end

        def get_filter
          URI.unescape(params[:filter]) if params[:filter]
        end
      end
    end
  end
end
