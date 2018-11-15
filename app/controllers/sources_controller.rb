class SourcesController < ApplicationController
  include WithComment
  actions_without_auth :existence, :index, :show, :datatable, :suggestions_datatable, :update_source_suggestion

  def index
    (sources, presenter) = if params[:detailed] == 'true'
         [
           Source.includes(authors_sources: [:author])
             .joins(:evidence_items)
             .order('sources.id asc')
             .page(params[:page])
             .per(params[:count])
             .uniq,
             SourceDetailPresenter
         ]
       else
         [
           Source.joins(:evidence_items)
             .order('sources.id asc')
             .page(params[:page])
             .per(params[:count])
             .uniq,
             SourcePresenter
         ]
       end

    sources = if params[:filter].present?
                description_search(pubmed_search(sources))
              else
                sources
              end

    render json: PaginatedCollectionPresenter.new(
      sources,
      request,
      presenter,
      PaginationPresenter,
      {
        filter: params[:filter] || {}
      },
      [:filter, :detailed]
    )
  end

  def show
    source = Source.includes(authors_sources: [:author])
      .find_by!(identifier_type => params[:id])

    render json: SourceDetailPresenter.new(source)
  end

  def create
    result = Source.propose(source_suggestion_params, comment_params, current_user)
    authorize result.source

    if result.succeeded?
      attach_comment(result.source)
      render json: SourceDetailPresenter.new(result.source), status: :created
    elsif result.errors.any? { |e| e =~ /already been submitted/ }
      render json: SourceDetailPresenter.new(result.source), status: :conflict
    else
      render json: result.errors, status: :internal_server_error
    end
  end

  def update
    status = params.permit(:status)
    source = Source.find_by(id: params[:id])
    authorize source
    if source.update_attributes(status)
      render json: SourceDetailPresenter.new(source)
    else
      render json: {errors: ['Failed to update status']}, status: :bad_request
    end
  end

  def update_source_suggestion
    status = params.permit(:status, :reason)
    suggestion = SourceSuggestion.find_by(id: params[:id])
    authorize suggestion
    if suggestion.update_attributes(status)
      render json: {}, status: :ok
    else
      render json: {errors: ['Failed to update status']}, status: :bad_request
    end
  end

  def existence
    proposed_citation_id = params[:citation_id]
    proposed_source_type = params[:source_type] || 'pubmed'
    (to_render, status) = if source = Source.find_by(citation_id: proposed_citation_id, source_type: proposed_source_type)
      [{ description: source.description, citation_id: source.citation_id, source_type: source.source_type, status: source.status}, :ok]
    elsif proposed_source_type == 'pubmed'
      if (citation = Scrapers::PubMed.get_citation_from_pubmed_id(proposed_citation_id)).present?
        [{ description: citation, citation_id: proposed_citation_id, source_type: proposed_source_type, status: 'new' }, :ok]
      else
        [{}, :not_found]
      end
    else
      [{}, :not_found]
    end
    render json: to_render, status: status
  end

  def datatable
    render json: SourceBrowseTable.new(view_context)
  end

  def suggestions_datatable
    render json: SourceSuggestionBrowseTable.new(view_context)
  end

  private
  def identifier_type
    case params[:identifier_type]
    when 'citation_id'
      :citation_id
    else
      :id
    end
  end

  def description_search(query)
    if (description = params[:filter][:description]).present?
      query.where('sources.description ILIKE :description', description: "%#{description}%")
    else
      query
    end
  end

  def pubmed_search(query)
    if (pubmed_id = params[:filter][:pubmed_id]).present?
      query.where('sources.citation_id ILIKE :pubmed_id AND sources.source_type =\'pubmed\'', pubmed_id: "%#{pubmed_id}%")
    else
      query
    end
  end

  def source_suggestion_params
    params.permit(:citation_id, :source_type, :gene_name, :variant_name, :disease_name)
  end
end
