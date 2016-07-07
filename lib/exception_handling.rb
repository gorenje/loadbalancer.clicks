class ExceptionHandling
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call env
    rescue => ex
      begin

        $librato_queue.add('adtekio.trk.clks' => {
          :source => "exception", :value => 1
        })
      rescue

      end
      [307, {'Location' => ENV['ERROR_PAGE_URL']}, []]
    end
  end
end
